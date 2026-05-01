from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import datetime
import os
from dotenv import load_dotenv

load_dotenv()

SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5432/chaincacao")

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

class MediaMetadata(Base):
    __tablename__ = "media_metadata"

    id = Column(Integer, primary_key=True, index=True)
    lot_hash = Column(String, index=True)
    filename = Column(String)
    file_path = Column(String)
    sha256_hash = Column(String, unique=True, index=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

# Create tables
def init_db():
    Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
