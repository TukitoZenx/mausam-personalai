"""003_add_reminders

Revision ID: 003_add_reminders
Revises: 002_add_saved_locations
Create Date: 2026-09-08 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

revision = '003_add_reminders'
down_revision = '002_add_saved_locations'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'reminders',
        sa.Column('id', sa.String(), nullable=False, primary_key=True),
        sa.Column('user_id', sa.String(), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('time_of_day', sa.String(), nullable=False),
        sa.Column('frequency', sa.String(), server_default='daily', nullable=False),
        sa.Column('location_id', sa.String(), sa.ForeignKey('saved_locations.id', ondelete='SET NULL'), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
        sa.Column('last_sent_at', sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(op.f('ix_reminders_id'), 'reminders', ['id'], unique=False)
    op.create_index(op.f('ix_reminders_user_id'), 'reminders', ['user_id'], unique=False)
    op.create_index('ix_reminders_user_time', 'reminders', ['user_id', 'time_of_day'], unique=False)


def downgrade() -> None:
    op.drop_index('ix_reminders_user_time', table_name='reminders')
    op.drop_index(op.f('ix_reminders_user_id'), table_name='reminders')
    op.drop_index(op.f('ix_reminders_id'), table_name='reminders')
    op.drop_table('reminders')
