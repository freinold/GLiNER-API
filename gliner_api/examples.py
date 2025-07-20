from functools import lru_cache

from pydantic import Field
from pydantic_settings import (
    BaseSettings,
    JsonConfigSettingsSource,
    PydanticBaseSettingsSource,
    SettingsConfigDict,
    YamlConfigSettingsSource,
)

from gliner_api.config import Config, get_config
from gliner_api.datamodel import Entity

config: Config = get_config()


class Examples(BaseSettings):
    invoke: list["InvokeExample"] = Field(
        default=[
            {
                "text": "Steve Jobs founded Apple Inc. in Cupertino, CA on April 1, 1976.",
                "entities": [
                    Entity(start=0, end=10, text="Steve Jobs", type="person", score=0.99),
                    Entity(start=19, end=24, text="Apple", type="organization", score=0.98),
                    Entity(start=28, end=37, text="Cupertino", type="location", score=0.98),
                    Entity(start=39, end=49, text="California", type="location", score=0.99),
                    Entity(start=53, end=66, text="April 1, 1976", type="date", score=0.68),
                ],
            }
        ]
    )
    batch: list["BatchExample"] = Field(
        default=[
            {
                "texts": [
                    [
                        "Steve Jobs founded Apple Inc. in Cupertino, CA on April 1, 1976.",
                        "Until her death in 2022, the head of the Windsor family, Queen Elizabeth, resided in London.",
                    ],
                ],
                "entities": [
                    [
                        Entity(start=0, end=10, text="Steve Jobs", type="person", score=0.99),
                        Entity(start=19, end=24, text="Apple", type="organization", score=0.98),
                        Entity(start=28, end=37, text="Cupertino", type="location", score=0.98),
                        Entity(start=39, end=49, text="California", type="location", score=0.99),
                        Entity(start=53, end=66, text="April 1, 1976", type="date", score=0.68),
                    ],
                    [
                        Entity(start=19, end=23, text="2022", type="date", score=0.38),
                        Entity(start=41, end=55, text="Windsor family", type="organization", score=0.90),
                        Entity(start=57, end=72, text="Queen Elizabeth", type="person", score=0.99),
                        Entity(start=85, end=91, text="London", type="location", score=0.99),
                    ],
                ],
            }
        ]
    )

    model_config: SettingsConfigDict = SettingsConfigDict(
        yaml_file="examples.yaml",
        yaml_file_encoding="utf-8",
        json_file="examples.json",
        json_file_encoding="utf-8",
    )

    @classmethod
    def settings_customise_sources(
        cls,
        settings_cls: type[BaseSettings],
        init_settings: PydanticBaseSettingsSource,
        env_settings: PydanticBaseSettingsSource,
        dotenv_settings: PydanticBaseSettingsSource,
        file_secret_settings: PydanticBaseSettingsSource,
    ) -> tuple[PydanticBaseSettingsSource, ...]:
        return (
            init_settings,
            YamlConfigSettingsSource(settings_cls=settings_cls),
            JsonConfigSettingsSource(settings_cls=settings_cls),
        )


class InvokeExample(BaseSettings):
    text: str
    threshold: float = Field(ge=0.0, le=1.0, default=config.default_threshold)
    entity_types: list[str] = Field(default=config.default_entities)
    flat_ner: bool = True
    multi_label: bool = False
    entities: list[Entity]


class BatchExample(BaseSettings):
    texts: list[str]
    threshold: float = Field(ge=0.0, le=1.0, default=config.default_threshold)
    entity_types: list[str] = Field(default=config.default_entities)
    flat_ner: bool = True
    multi_label: bool = False
    entities: list[list[Entity]]


@lru_cache
def get_examples() -> Examples:
    """Get the examples for the API docs and the frontend."""
    return Examples()
