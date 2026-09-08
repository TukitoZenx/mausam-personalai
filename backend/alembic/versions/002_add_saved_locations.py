"""002_add_saved_locations

Revision ID: 002_add_saved_locations
Revises: 001_create_users
Create Date: 2026-09-01 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from geoalchemy2 import Geography

revision = '002_add_saved_locations'
down_revision = '001_create_users'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Ensure PostGIS extension is loaded for Geography data type
    op.execute("CREATE EXTENSION IF NOT EXISTS postgis")

    op.create_table(
        'saved_locations',
        sa.Column('id', sa.String(), nullable=False, primary_key=True),
        sa.Column('user_id', sa.String(), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('name', sa.String(), nullable=False),
        sa.Column('latitude', sa.Float(), nullable=False),
        sa.Column('longitude', sa.Float(), nullable=False),
        sa.Column('geo_point', Geography(geometry_type='POINT', srid=4326), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
    )
    op.create_index(op.f('ix_saved_locations_user_id'), 'saved_locations', ['user_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_saved_locations_user_id'), table_name='saved_locations')
    op.drop_table('saved_locations')
