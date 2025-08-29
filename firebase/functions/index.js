const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });

admin.initializeApp();

const db = admin.firestore();

// MARK: - Route Generation Cloud Function

exports.generateRoute = functions.https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { 
        interests, 
        duration, 
        startLocation, 
        maxDistance,
        includeClosedPOIs = false 
    } = data;

    try {
        // Get all POIs
        const poisSnapshot = await db.collection('poi').get();
        const pois = poisSnapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));

        // Filter POIs based on interests and availability
        let filteredPOIs = pois.filter(poi => {
            // Check if POI matches interests
            const matchesInterests = !interests || interests.length === 0 || 
                interests.some(interest => poi.categories.includes(interest));
            
            // Check if POI is open (if not including closed POIs)
            const isOpen = includeClosedPOIs || isPOIOpen(poi);
            
            return matchesInterests && isOpen;
        });

        // If start location provided, sort by distance
        if (startLocation) {
            filteredPOIs.sort((a, b) => {
                const distA = calculateDistance(startLocation, a.coordinates);
                const distB = calculateDistance(startLocation, b.coordinates);
                return distA - distB;
            });
        }

        // Generate optimal route
        const route = await generateOptimalRoute(
            filteredPOIs, 
            duration, 
            startLocation, 
            maxDistance
        );

        // Cache the generated route
        await cacheGeneratedRoute(context.auth.uid, route, data);

        return {
            success: true,
            route: route
        };

    } catch (error) {
        console.error('Error generating route:', error);
        throw new functions.https.HttpsError('internal', 'Failed to generate route');
    }
});

// MARK: - Anti-Spam and Moderation Functions

exports.checkSpamQuota = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { contentType, poiId } = data; // contentType: 'review' or 'question'
    const userId = context.auth.uid;

    try {
        const now = admin.firestore.Timestamp.now();
        const oneDayAgo = new Date(now.toDate().getTime() - 24 * 60 * 60 * 1000);

        // Check user's activity in the last 24 hours
        const activityQuery = await db.collection(contentType === 'review' ? 'reviews' : 'questions')
            .where('userId', '==', userId)
            .where('createdAt', '>', oneDayAgo)
            .get();

        const dailyCount = activityQuery.size;
        const maxDaily = contentType === 'review' ? 10 : 5; // 10 reviews or 5 questions per day

        if (dailyCount >= maxDaily) {
            throw new functions.https.HttpsError('resource-exhausted', 
                `Daily limit exceeded. Maximum ${maxDaily} ${contentType}s per day.`);
        }

        // Check for duplicate content
        const duplicateQuery = await db.collection(contentType === 'review' ? 'reviews' : 'questions')
            .where('userId', '==', userId)
            .where('poiId', '==', poiId)
            .where('createdAt', '>', oneDayAgo)
            .get();

        if (!duplicateQuery.empty) {
            throw new functions.https.HttpsError('already-exists', 
                `You have already posted a ${contentType} for this POI today.`);
        }

        return { 
            success: true, 
            remainingQuota: maxDaily - dailyCount - 1 
        };

    } catch (error) {
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        console.error('Error checking spam quota:', error);
        throw new functions.https.HttpsError('internal', 'Failed to check quota');
    }
});

exports.moderateContent = functions.firestore
    .document('reviews/{reviewId}')
    .onCreate(async (snap, context) => {
        const review = snap.data();
        
        try {
            // Simple content moderation
            const moderationResult = await moderateText(review.text || '');
            
            if (moderationResult.isFlagged) {
                // Update review with moderation flags
                await snap.ref.update({
                    reported: true,
                    moderationFlags: moderationResult.flags,
                    isHidden: moderationResult.shouldHide
                });

                // Notify moderators if content is hidden
                if (moderationResult.shouldHide) {
                    await notifyModerators(review, 'review');
                }
            }

        } catch (error) {
            console.error('Error moderating review:', error);
        }
    });

exports.moderateQuestion = functions.firestore
    .document('questions/{questionId}')
    .onCreate(async (snap, context) => {
        const question = snap.data();
        
        try {
            // Simple content moderation
            const moderationResult = await moderateText(question.text);
            
            if (moderationResult.isFlagged) {
                // Update question with moderation flags
                await snap.ref.update({
                    reported: true,
                    moderationFlags: moderationResult.flags,
                    isHidden: moderationResult.shouldHide
                });

                // Notify moderators if content is hidden
                if (moderationResult.shouldHide) {
                    await notifyModerators(question, 'question');
                }
            }

        } catch (error) {
            console.error('Error moderating question:', error);
        }
    });

// MARK: - Content Import/ETL Functions

exports.importOSMData = functions.https.onRequest(async (req, res) => {
    cors(req, res, async () => {
        try {
            const { bounds, categories } = req.body;
            
            // Validate request
            if (!bounds || !categories) {
                res.status(400).json({ error: 'Missing required parameters' });
                return;
            }

            // Import POIs from OpenStreetMap
            const pois = await importFromOSM(bounds, categories);
            
            // Transform and save to Firestore
            const savedCount = await savePOIsToFirestore(pois);
            
            res.json({ 
                success: true, 
                importedCount: pois.length,
                savedCount: savedCount 
            });

        } catch (error) {
            console.error('Error importing OSM data:', error);
            res.status(500).json({ error: 'Failed to import data' });
        }
    });
});

exports.importWikidata = functions.https.onRequest(async (req, res) => {
    cors(req, res, async () => {
        try {
            const { poiIds } = req.body;
            
            if (!poiIds || !Array.isArray(poiIds)) {
                res.status(400).json({ error: 'Missing or invalid poiIds' });
                return;
            }

            // Import additional data from Wikidata
            const enrichedPOIs = await enrichPOIsWithWikidata(poiIds);
            
            // Update existing POIs in Firestore
            const updatedCount = await updatePOIsInFirestore(enrichedPOIs);
            
            res.json({ 
                success: true, 
                updatedCount: updatedCount 
            });

        } catch (error) {
            console.error('Error importing Wikidata:', error);
            res.status(500).json({ error: 'Failed to import Wikidata' });
        }
    });
});

// MARK: - Helper Functions

function isPOIOpen(poi) {
    if (!poi.openingHours) return true;
    
    const now = new Date();
    const currentTime = now.getHours() * 60 + now.getMinutes();
    const dayOfWeek = now.getDay();
    
    // Simple parsing of opening hours (format: "Mo-Fr 09:00-18:00; Sa 10:00-16:00")
    const hours = poi.openingHours.split(';');
    
    for (const hour of hours) {
        const [days, time] = hour.trim().split(' ');
        if (isDayInRange(days, dayOfWeek) && isTimeInRange(time, currentTime)) {
            return true;
        }
    }
    
    return false;
}

function isDayInRange(days, currentDay) {
    // Simple day range parsing (Mo-Fr, Sa, etc.)
    const dayMap = { 'Mo': 1, 'Tu': 2, 'We': 3, 'Th': 4, 'Fr': 5, 'Sa': 6, 'Su': 0 };
    
    if (days.includes('-')) {
        const [start, end] = days.split('-');
        const startDay = dayMap[start];
        const endDay = dayMap[end];
        
        if (startDay <= endDay) {
            return currentDay >= startDay && currentDay <= endDay;
        } else {
            // Cross-week range (e.g., Fr-Mo)
            return currentDay >= startDay || currentDay <= endDay;
        }
    } else {
        return dayMap[days] === currentDay;
    }
}

function isTimeInRange(timeRange, currentTime) {
    const [start, end] = timeRange.split('-');
    const startTime = parseTimeToMinutes(start);
    const endTime = parseTimeToMinutes(end);
    
    if (startTime <= endTime) {
        return currentTime >= startTime && currentTime <= endTime;
    } else {
        // Cross-midnight range
        return currentTime >= startTime || currentTime <= endTime;
    }
}

function parseTimeToMinutes(timeStr) {
    const [hours, minutes] = timeStr.split(':').map(Number);
    return hours * 60 + minutes;
}

function calculateDistance(point1, point2) {
    const R = 6371; // Earth's radius in km
    const dLat = (point2.lat - point1.lat) * Math.PI / 180;
    const dLon = (point2.lng - point1.lng) * Math.PI / 180;
    const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
              Math.cos(point1.lat * Math.PI / 180) * Math.cos(point2.lat * Math.PI / 180) *
              Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
}

async function generateOptimalRoute(pois, targetDuration, startLocation, maxDistance) {
    const route = {
        id: `generated_${Date.now()}`,
        title: `Персонализированный маршрут`,
        durationMinutes: 0,
        distanceKm: 0,
        stops: [],
        polyline: [],
        tags: ['generated'],
        meta: {
            generatedAt: new Date().toISOString(),
            targetDuration: targetDuration,
            startLocation: startLocation
        }
    };

    let currentLocation = startLocation;
    let remainingTime = targetDuration * 60; // Convert to minutes
    let totalDistance = 0;

    // Greedy algorithm: select nearest POI that fits time constraints
    while (remainingTime > 0 && pois.length > 0) {
        let bestPOI = null;
        let bestScore = -1;

        for (let i = 0; i < pois.length; i++) {
            const poi = pois[i];
            const distance = currentLocation ? 
                calculateDistance(currentLocation, poi.coordinates) : 0;
            
            // Estimate time to visit POI (travel + dwell)
            const travelTime = distance * 20; // 20 min per km walking
            const dwellTime = estimateDwellTime(poi);
            const totalTime = travelTime + dwellTime;

            if (totalTime <= remainingTime && distance <= maxDistance) {
                const score = calculatePOIScore(poi, distance, dwellTime);
                if (score > bestScore) {
                    bestScore = score;
                    bestPOI = { ...poi, index: i };
                }
            }
        }

        if (!bestPOI) break;

        // Add POI to route
        const distance = currentLocation ? 
            calculateDistance(currentLocation, bestPOI.coordinates) : 0;
        const dwellTime = estimateDwellTime(bestPOI);

        route.stops.push({
            poiId: bestPOI.id,
            note: `Посещение ${bestPOI.title}`,
            dwellMin: Math.round(dwellTime)
        });

        route.durationMinutes += Math.round(distance * 20 + dwellTime);
        totalDistance += distance;
        currentLocation = bestPOI.coordinates;

        // Remove selected POI from available list
        pois.splice(bestPOI.index, 1);
        remainingTime -= (distance * 20 + dwellTime);
    }

    route.distanceKm = Math.round(totalDistance * 100) / 100;
    route.polyline = generatePolyline(route.stops, startLocation);
    route.title = generateRouteTitle(route.durationMinutes, route.stops.length);

    return route;
}

function estimateDwellTime(poi) {
    // Estimate time spent at POI based on category
    const categoryDwellTimes = {
        'музей': 60,      // 1 hour
        'памятник': 15,   // 15 minutes
        'парк': 45,       // 45 minutes
        'кафе': 30,       // 30 minutes
        'ресторан': 60,   // 1 hour
        'магазин': 20,    // 20 minutes
        'церковь': 30,    // 30 minutes
        'театр': 120,     // 2 hours
        'кинотеатр': 150, // 2.5 hours
        'default': 30     // 30 minutes default
    };

    for (const category of poi.categories) {
        if (categoryDwellTimes[category]) {
            return categoryDwellTimes[category];
        }
    }
    return categoryDwellTimes.default;
}

function calculatePOIScore(poi, distance, dwellTime) {
    // Calculate POI score based on rating, distance, and category preference
    let score = (poi.rating || 0) * 10; // Rating weight
    
    // Distance penalty (closer is better)
    score -= distance * 5;
    
    // Dwell time bonus (more time = more interesting)
    score += dwellTime * 0.5;
    
    return score;
}

function generatePolyline(stops, startLocation) {
    // Generate polyline coordinates for the route
    const polyline = [];
    
    if (startLocation) {
        polyline.push(startLocation);
    }
    
    for (const stop of stops) {
        // In a real implementation, you would fetch POI coordinates
        // For now, we'll use placeholder coordinates
        polyline.push({ lat: 54.1838, lng: 45.1749 }); // Saransk coordinates
    }
    
    return polyline;
}

function generateRouteTitle(durationMinutes, stopCount) {
    const hours = Math.floor(durationMinutes / 60);
    const minutes = durationMinutes % 60;
    
    if (hours > 0) {
        return `Маршрут на ${hours}ч ${minutes}мин (${stopCount} мест)`;
    } else {
        return `Маршрут на ${minutes}мин (${stopCount} мест)`;
    }
}

async function cacheGeneratedRoute(userId, route, parameters) {
    // Cache generated route for future reference
    await db.collection('generated_routes').add({
        userId: userId,
        route: route,
        parameters: parameters,
        createdAt: admin.firestore.Timestamp.now(),
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000) // 24 hours
    });
}

async function moderateText(text) {
    // Simple text moderation (in production, use ML services)
    const spamWords = ['спам', 'реклама', 'купить', 'продать', 'заработок'];
    const inappropriateWords = ['нецензурное', 'слово'];
    
    const lowerText = text.toLowerCase();
    const flags = [];
    let shouldHide = false;
    
    // Check for spam words
    for (const word of spamWords) {
        if (lowerText.includes(word)) {
            flags.push('spam');
            shouldHide = true;
        }
    }
    
    // Check for inappropriate content
    for (const word of inappropriateWords) {
        if (lowerText.includes(word)) {
            flags.push('inappropriate');
            shouldHide = true;
        }
    }
    
    // Check for excessive repetition
    const words = text.split(' ');
    const wordCount = {};
    for (const word of words) {
        wordCount[word] = (wordCount[word] || 0) + 1;
        if (wordCount[word] > 5) {
            flags.push('repetitive');
            shouldHide = true;
        }
    }
    
    return {
        isFlagged: flags.length > 0,
        flags: flags,
        shouldHide: shouldHide
    };
}

async function notifyModerators(content, contentType) {
    // Notify moderators about flagged content
    await db.collection('moderation_queue').add({
        contentType: contentType,
        contentId: content.id,
        poiId: content.poiId,
        userId: content.userId,
        text: content.text,
        flags: content.moderationFlags,
        createdAt: admin.firestore.Timestamp.now(),
        status: 'pending'
    });
}

async function importFromOSM(bounds, categories) {
    // Import POIs from OpenStreetMap
    // This is a placeholder - in production, you would use OSM API
    const pois = [];
    
    // Example structure for imported POI
    const samplePOI = {
        id: `osm_${Date.now()}`,
        title: 'Sample POI from OSM',
        categories: categories,
        coordinates: {
            lat: (bounds.north + bounds.south) / 2,
            lng: (bounds.east + bounds.west) / 2
        },
        address: 'Sample address',
        openingHours: 'Mo-Fr 09:00-18:00',
        short: 'Sample description',
        description: 'Detailed description from OSM',
        images: [],
        audio: [],
        rating: 0,
        tags: ['imported', 'osm'],
        meta: {
            source: 'osm',
            importedAt: new Date().toISOString()
        }
    };
    
    pois.push(samplePOI);
    return pois;
}

async function savePOIsToFirestore(pois) {
    let savedCount = 0;
    
    for (const poi of pois) {
        try {
            await db.collection('poi').doc(poi.id).set(poi);
            savedCount++;
        } catch (error) {
            console.error(`Error saving POI ${poi.id}:`, error);
        }
    }
    
    return savedCount;
}

async function enrichPOIsWithWikidata(poiIds) {
    // Enrich POIs with additional data from Wikidata
    // This is a placeholder - in production, you would use Wikidata API
    const enrichedPOIs = [];
    
    for (const poiId of poiIds) {
        const enrichedPOI = {
            id: poiId,
            wikidataId: `Q${Math.floor(Math.random() * 1000000)}`,
            description: 'Enhanced description from Wikidata',
            meta: {
                wikidataEnriched: true,
                enrichedAt: new Date().toISOString()
            }
        };
        
        enrichedPOIs.push(enrichedPOI);
    }
    
    return enrichedPOIs;
}

async function updatePOIsInFirestore(enrichedPOIs) {
    let updatedCount = 0;
    
    for (const enrichedPOI of enrichedPOIs) {
        try {
            await db.collection('poi').doc(enrichedPOI.id).update(enrichedPOI);
            updatedCount++;
        } catch (error) {
            console.error(`Error updating POI ${enrichedPOI.id}:`, error);
        }
    }
    
    return updatedCount;
}

module.exports = {
    generateRoute: exports.generateRoute,
    checkSpamQuota: exports.checkSpamQuota,
    moderateContent: exports.moderateContent,
    moderateQuestion: exports.moderateQuestion,
    importOSMData: exports.importOSMData,
    importWikidata: exports.importWikidata
};