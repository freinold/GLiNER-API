from pydantic import AliasChoices, BaseModel, Field


class Entity(BaseModel):
    start: int = Field(
        ge=0,
        description="Start index of the entity in the input text",
    )
    end: int = Field(
        ge=0,
        description="End index of the entity in the input text",
    )
    text: str = Field(
        description="Text of the entity, extracted from the input text",
    )
    type: str = Field(
        validation_alias=AliasChoices("type", "label"),
        description="Entity type or label",
    )
    score: float = Field(
        ge=0.0,
        le=1.0,
        description="Confidence score of the entity detection, between 0 and 1",
    )
