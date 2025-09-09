from pydantic import BaseModel, Field, TypeAdapter

from gliner_api import Entity
from gliner_api.config import get_config
from gliner_api.examples import Examples, get_examples

examples: Examples = get_examples()


class ErrorMessage(BaseModel):
    error: str = Field(description="Short error code")
    detail: str = Field(description="Detailed error explanaiton")


class InvokeRequest(BaseModel):
    text: str = Field(
        description="Input text to analyze for entities",
        examples=[example.text for example in examples.invoke],
    )
    threshold: float = Field(
        default_factory=lambda: get_config().default_threshold,
        description="Threshold for entity detection; if not set, uses default threshold (see gliner config from /api/info endpoint)",
        examples=[example.threshold for example in examples.invoke],
        ge=0.0,
        le=1.0,
    )
    entity_types: list[str] = Field(
        default_factory=lambda: get_config().default_entities,
        description="List of entity types to detect; if not set, uses default entities (see gliner config from /api/info endpoint)",
        examples=[example.entity_types for example in examples.invoke],
    )
    flat_ner: bool = Field(
        default=True,
        description="Whether to return flat entities (default: True). If False, returns nested entities.",
        examples=[example.flat_ner for example in examples.invoke],
    )
    multi_label: bool = Field(
        default=False,
        description="Whether to allow multiple labels per entity (default: False). If True, there can be multiple entities returned for the same span.",
        examples=[example.multi_label for example in examples.invoke],
    )


class InvokeResponse(BaseModel):
    entities: list[Entity] = Field(
        description="List of detected entities in the input text",
        examples=[example.entities for example in examples.invoke],
    )


class BatchRequest(BaseModel):
    texts: list[str] = Field(
        description="List of input texts to analyze for entities",
        examples=[example.texts for example in examples.batch],
        min_length=1,
    )
    threshold: float = Field(
        default_factory=lambda: get_config().default_threshold,
        description="Threshold for entity detection; if not set, uses default threshold (see gliner config from /api/info endpoint)",
        examples=[example.threshold for example in examples.batch],
        ge=0.0,
        le=1.0,
    )
    entity_types: list[str] = Field(
        default_factory=lambda: get_config().default_entities,
        description="List of entity types to detect; if not set, uses default entities (see gliner config from /api/info endpoint)",
        examples=[example.entity_types for example in examples.batch],
    )
    flat_ner: bool = Field(
        default=True,
        description="Whether to return flat entities (default: True). If False, returns nested entities.",
        examples=[example.flat_ner for example in examples.batch],
    )
    multi_label: bool = Field(
        default=False,
        description="Whether to allow multiple labels per entity (default: False). If True, there can be multiple entities returned for the same span.",
        examples=[example.multi_label for example in examples.batch],
    )


class BatchResponse(BaseModel):
    entities: list[list[Entity]] = Field(
        description="List of lists of detected entities for each input text",
        examples=[example.entities for example in examples.batch],
    )


class HealthCheckResponse(BaseModel):
    status: str = Field(
        description="Health status of the GLiNER API",
        examples=["healthy"],
    )


class InfoResponse(BaseModel):
    model_id: str = Field(
        default_factory=lambda: get_config().model_id,
        description="The Huggingface model ID for a GLiNER model.",
    )
    default_entities: list[str] = Field(
        default_factory=lambda: get_config().default_entities,
        description="The default entities to be detected, used if request includes no specific entities.",
    )
    default_threshold: float = Field(
        default_factory=lambda: get_config().default_threshold,
        description="The default threshold for entity detection, used if request includes no specific threshold.",
        ge=0.0,
        le=1.0,
    )
    api_key_required: bool = Field(
        default_factory=lambda: get_config().api_key is not None,
        description="Whether an API key is required for requests",
    )
    configured_use_case: str = Field(
        default_factory=lambda: get_config().use_case,
        description="The configured use case for this deployment",
    )
    onnx_enabled: bool = Field(
        default_factory=lambda: get_config().backend,
        description="Whether the GLiNER model is loaded as an ONNX model",
    )


# Define TypeAdapter for Entity list once and reuse it
entity_list_adapter: TypeAdapter[list[Entity]] = TypeAdapter(type=list[Entity])
deep_entity_list_adapter: TypeAdapter[list[list[Entity]]] = TypeAdapter(type=list[list[Entity]])
