from typing import List, Optional
from app.schemas.contents import Content
from typing import List, Dict
from app.db.models.contents import Content
from app.db.session import SessionLocal
from app.db.models.contents import Content as ContentORM
from app.schemas.contents import Content as ContentSchema

# 💡 지금은 더미 콘텐츠 데이터 사용 중 (나중에 DB로 교체 가능)
# FAKE_CONTENT_DB = [
#     Content(id=1, title="Inception", description="Dream within a dream", category="sf", year=2010),
#     Content(id=2, title="Parasite", description="Social satire", category="drama", year=2019),
#     Content(id=3, title="Interstellar", description="Space adventure", category="sf", year=2014),
#     Content(id=4, title="The Glory", description="Revenge drama", category="drama", year=2023),
#     Content(id=5, title="Everything Everywhere All at Once", description="Multiverse chaos", category="sf", year=2022),
#     Content(id=6, title="The Social Network", description="Rise of Facebook", category="drama", year=2010),
#     Content(id=7, title="Her", description="AI love story", category="sf", year=2013),
#     Content(id=8, title="Whiplash", description="Obsessive ambition", category="drama", year=2014),
#     Content(id=9, title="Dune", description="Desert power", category="sf", year=2021),
#     Content(id=10, title="Chernobyl", description="Nuclear disaster", category="drama", year=2019),
# ]




def seed_fake_contents():
    db = SessionLocal()

    fake_contents = [
        Content(id=1, title="Inception", description="Dream within a dream", category="sf", year=2010),
        Content(id=2, title="Parasite", description="Social satire", category="drama", year=2019),
        Content(id=3, title="Interstellar", description="Space adventure", category="sf", year=2014),
        Content(id=4, title="The Glory", description="Revenge drama", category="drama", year=2023),
        Content(id=5, title="Everything Everywhere All at Once", description="Multiverse chaos", category="sf", year=2022),
        Content(id=6, title="The Social Network", description="Rise of Facebook", category="drama", year=2010),
        Content(id=7, title="Her", description="AI love story", category="sf", year=2013),
        Content(id=8, title="Whiplash", description="Obsessive ambition", category="drama", year=2014),
        Content(id=9, title="Dune", description="Desert power", category="sf", year=2021),
        Content(id=10, title="Chernobyl", description="Nuclear disaster", category="drama", year=2019),
    ]

    db.bulk_save_objects(fake_contents)
    db.commit()
    db.close()


def get_all_contents(category: Optional[str] = None) -> List[ContentSchema]:
    db: Session = SessionLocal()

    if category:
        contents = db.query(ContentORM).filter(ContentORM.category == category).all()
    else:
        contents = db.query(ContentORM).all()

    return contents


def get_content_by_id(content_id: int) -> Optional[ContentSchema]:
    db: Session = SessionLocal()
    content = db.query(ContentORM).filter(ContentORM.id == content_id).first()
    return content

# 나중에 db로 교체 시 
#  1.모델에 파일만들기: models/orm/content_orm.py 만들기 → SQLAlchemy ORM 클래스 정의
#  2.service.py에서 더미 리스트 제거 → DB 쿼리로 대체
#  3.router.py에서 db: Session = Depends(get_db) 추가

#타입힌트
# recommend에서 3번 작성 할 때 ,
# contents_service.contents는 그냥 리스트(List[dict]) 같은 변수인데,
# Python에서 동적으로 정의된 변수는 **정적 타입 분석기(Pylance 등)**가 정확히 추적 못해서
# contents/service에 타입 힌트 추가하면 빨간줄 사라짐! (Python이 "이건 리스트임!" 하고 알려주는 셈)
contents: List[Dict] = [
    {
        "id": 1,
        "title": "The Matrix",
        "category": "sf",
        "year": 1999,
        "description": "A computer hacker learns about the true nature of reality."
    },
    {
        "id": 2,
        "title": "The Godfather",
        "category": "drama",
        "year": 1972,
        "description": "The aging patriarch of an organized crime dynasty transfers control to his reluctant son."
    },
    # ... 추가 데이터
]
