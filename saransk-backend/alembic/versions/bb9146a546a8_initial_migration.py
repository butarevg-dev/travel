"""Initial migration

Revision ID: bb9146a546a8
Revises: 
Create Date: 2025-08-25 13:18:58.770450

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'bb9146a546a8'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Create enum types
    placecategory = postgresql.ENUM('monument', 'architecture', 'food', 'souvenir', name='placecategory')
    placesubcategory = postgresql.ENUM('historical_person', 'military_glory', 'cultural_heritage', 'orthodox_church', 'modern', 'soviet_modernism', 'wooden_architecture', 'contemporary', 'mordovian_cuisine', 'cafe', 'restaurant', 'street_food', 'coffee_shop', 'vegetarian', 'crafts_ethno', 'official_store', 'market_fair', 'workshop', name='placesubcategory')
    pricetier = postgresql.ENUM('free', 'budget', 'medium', 'premium', name='pricetier')
    authprovider = postgresql.ENUM('apple', 'email', name='authprovider')
    reviewstatus = postgresql.ENUM('pending', 'approved', 'rejected', 'hidden', name='reviewstatus')
    
    placecategory.create(op.get_bind())
    placesubcategory.create(op.get_bind())
    pricetier.create(op.get_bind())
    authprovider.create(op.get_bind())
    reviewstatus.create(op.get_bind())
    
    # Create users table
    op.create_table('users',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.Column('auth_provider', postgresql.ENUM('apple', 'email', name='authprovider'), nullable=False),
        sa.Column('auth_id', sa.String(length=255), nullable=False),
        sa.Column('email', sa.String(length=255), nullable=True),
        sa.Column('name', sa.String(length=255), nullable=True),
        sa.Column('language', sa.String(length=10), nullable=True),
        sa.Column('interests', sa.JSON(), nullable=True),
        sa.Column('preferences', sa.JSON(), nullable=True),
        sa.Column('is_premium', sa.Boolean(), nullable=True),
        sa.Column('premium_expires_at', sa.String(length=50), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('is_verified', sa.Boolean(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_users_id'), 'users', ['id'], unique=False)
    op.create_index(op.f('ix_users_auth_id'), 'users', ['auth_id'], unique=True)
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=True)
    
    # Create places table
    op.create_table('places',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.Column('title_ru', sa.String(length=255), nullable=False),
        sa.Column('title_en', sa.String(length=255), nullable=False),
        sa.Column('description_ru', sa.Text(), nullable=False),
        sa.Column('description_en', sa.Text(), nullable=False),
        sa.Column('category', postgresql.ENUM('monument', 'architecture', 'food', 'souvenir', name='placecategory'), nullable=False),
        sa.Column('subcategory', postgresql.ENUM('historical_person', 'military_glory', 'cultural_heritage', 'orthodox_church', 'modern', 'soviet_modernism', 'wooden_architecture', 'contemporary', 'mordovian_cuisine', 'cafe', 'restaurant', 'street_food', 'coffee_shop', 'vegetarian', 'crafts_ethno', 'official_store', 'market_fair', 'workshop', name='placesubcategory'), nullable=False),
        sa.Column('tags', postgresql.ARRAY(sa.String()), nullable=True),
        sa.Column('latitude', sa.Float(), nullable=False),
        sa.Column('longitude', sa.Float(), nullable=False),
        sa.Column('address_ru', sa.String(length=500), nullable=True),
        sa.Column('address_en', sa.String(length=500), nullable=True),
        sa.Column('price_tier', postgresql.ENUM('free', 'budget', 'medium', 'premium', name='pricetier'), nullable=True),
        sa.Column('is_commercial', sa.Boolean(), nullable=True),
        sa.Column('website', sa.String(length=500), nullable=True),
        sa.Column('phone', sa.String(length=50), nullable=True),
        sa.Column('hours_json', sa.Text(), nullable=True),
        sa.Column('photos', postgresql.ARRAY(sa.String()), nullable=True),
        sa.Column('audio_url_ru', sa.String(length=500), nullable=True),
        sa.Column('audio_url_en', sa.String(length=500), nullable=True),
        sa.Column('wheelchair_accessible', sa.Boolean(), nullable=True),
        sa.Column('audio_description', sa.Boolean(), nullable=True),
        sa.Column('rating_overall', sa.Float(), nullable=True),
        sa.Column('rating_interest', sa.Float(), nullable=True),
        sa.Column('rating_informativeness', sa.Float(), nullable=True),
        sa.Column('rating_convenience', sa.Float(), nullable=True),
        sa.Column('reviews_count', sa.Integer(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_places_id'), 'places', ['id'], unique=False)
    
    # Create reviews table
    op.create_table('reviews',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.Column('place_id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('text', sa.Text(), nullable=False),
        sa.Column('photos', postgresql.ARRAY(sa.String()), nullable=True),
        sa.Column('rating_interest', sa.Float(), nullable=False),
        sa.Column('rating_informativeness', sa.Float(), nullable=False),
        sa.Column('rating_convenience', sa.Float(), nullable=False),
        sa.Column('status', postgresql.ENUM('pending', 'approved', 'rejected', 'hidden', name='reviewstatus'), nullable=True),
        sa.Column('moderation_notes', sa.Text(), nullable=True),
        sa.Column('reports_count', sa.Integer(), nullable=True),
        sa.Column('toxicity_score', sa.Float(), nullable=True),
        sa.Column('spam_score', sa.Float(), nullable=True),
        sa.ForeignKeyConstraint(['place_id'], ['places.id'], ),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_reviews_id'), 'reviews', ['id'], unique=False)
    
    # Create route_templates table
    op.create_table('route_templates',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.Column('name_ru', sa.String(length=255), nullable=False),
        sa.Column('name_en', sa.String(length=255), nullable=False),
        sa.Column('description_ru', sa.String(length=1000), nullable=True),
        sa.Column('description_en', sa.String(length=1000), nullable=True),
        sa.Column('duration_minutes', sa.Integer(), nullable=False),
        sa.Column('distance_km', sa.Float(), nullable=True),
        sa.Column('place_ids', sa.JSON(), nullable=False),
        sa.Column('categories', sa.JSON(), nullable=True),
        sa.Column('tags', sa.JSON(), nullable=True),
        sa.Column('is_premium', sa.Boolean(), nullable=True),
        sa.Column('is_featured', sa.Boolean(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_route_templates_id'), 'route_templates', ['id'], unique=False)
    
    # Create generated_routes table
    op.create_table('generated_routes',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('duration_minutes', sa.Integer(), nullable=False),
        sa.Column('distance_km', sa.Float(), nullable=True),
        sa.Column('place_ids', sa.JSON(), nullable=False),
        sa.Column('interests', sa.JSON(), nullable=True),
        sa.Column('constraints', sa.JSON(), nullable=True),
        sa.Column('route_data', sa.JSON(), nullable=True),
        sa.Column('offline_pack_id', sa.String(length=255), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_generated_routes_id'), 'generated_routes', ['id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_generated_routes_id'), table_name='generated_routes')
    op.drop_table('generated_routes')
    op.drop_index(op.f('ix_route_templates_id'), table_name='route_templates')
    op.drop_table('route_templates')
    op.drop_index(op.f('ix_reviews_id'), table_name='reviews')
    op.drop_table('reviews')
    op.drop_index(op.f('ix_places_id'), table_name='places')
    op.drop_table('places')
    op.drop_index(op.f('ix_users_email'), table_name='users')
    op.drop_index(op.f('ix_users_auth_id'), table_name='users')
    op.drop_index(op.f('ix_users_id'), table_name='users')
    op.drop_table('users')
    
    # Drop enum types
    op.execute('DROP TYPE reviewstatus')
    op.execute('DROP TYPE authprovider')
    op.execute('DROP TYPE pricetier')
    op.execute('DROP TYPE placesubcategory')
    op.execute('DROP TYPE placecategory')