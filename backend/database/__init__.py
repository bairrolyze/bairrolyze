from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from config.settings import settings

# Convert postgresql:// to postgresql+asyncpg://
DATABASE_URL = settings.database_url.replace("postgresql://", "postgresql+asyncpg://")

engine = create_async_engine(DATABASE_URL, echo=settings.debug)
async_session_maker = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

Base = declarative_base()


async def get_db():
    """Dependency for FastAPI routes"""
    async with async_session_maker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
