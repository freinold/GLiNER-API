from pydantic import BaseModel, Field
from pydantic_settings import (
    BaseSettings,
    JsonConfigSettingsSource,
    PydanticBaseSettingsSource,
    SettingsConfigDict,
)


class Translations(BaseSettings):
    languages: dict[str, "Language"] = Field(
        default_factory=dict,
    )

    model_config = SettingsConfigDict(
        json_file="translations.json",
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
            JsonConfigSettingsSource(settings_cls),
        )


class Language(BaseModel):
    # TextInput properties
    input_label: str
    input_info: str
    input_placeholder: str

    # ThresholdSlider properties
    slider_label: str
    slider_info: str

    # EntityDropdown properties
    dropdown_label: str
    dropdown_info: str

    # OptionsCheckboxGroup properties
    options_label: str
    options_info: str
    options_deep_ner: str
    options_multi_label: str

    # OutputsLabels properties
    outputs_highlighted_text: str
    outputs_label: str
    outputs_json: str
