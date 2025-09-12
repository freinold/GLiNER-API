from logging import Logger

from gliner_api.logging import getLogger

logger: Logger = getLogger("gliner-api.version")


def get_version() -> str:
    if version := _get_git_version():
        logger.info(f"Version {version} (from git)")
        return version
    elif version := _get_package_version():
        logger.info(f"Version {version} (from package metadata)")
        return version
    elif version := _get_file_version():
        logger.info(f"Version {version} (from .app-version file)")
        return version
    else:
        logger.warning("No version found")
        return "unknown"


def _get_git_version() -> str | None:
    version: str | None = None

    # Try to get the version from the git repository
    try:
        from git import Repo

        repo = Repo(search_parent_directories=True)
        current_commit_hash: str = repo.commit("HEAD").hexsha

        # Check if the current commit is tagged
        for tag in repo.tags:
            if tag.commit.hexsha == current_commit_hash:
                return tag.name

        # If the current commit is not tagged, use the commit hash stub
        if version is None:
            return current_commit_hash[:8]

    # Fallback to None if no git repository is found
    except Exception as e:
        logger.debug("Failed to get version from git", exc_info=e)
        return None


def _get_package_version() -> str | None:
    """Get version from package metadata."""
    try:
        from importlib.metadata import version

        # Try to get version from installed package metadata
        package_version: str = version("gliner-api")
        return package_version

    except ImportError:
        logger.debug("importlib.metadata not available")
        return None
    except Exception as e:
        # This will catch PackageNotFoundError and any other exceptions
        logger.debug("Failed to get version from package metadata", exc_info=e)
        return None


def _get_file_version() -> str | None:
    """Get version from .app-version file in project root."""
    try:
        from pathlib import Path

        # Find project root by looking for pyproject.toml
        current_path = Path(__file__).parent
        while current_path != current_path.parent:
            if (current_path / "pyproject.toml").exists():
                break
            current_path = current_path.parent
        else:
            # Fallback: assume project root is one level up from gliner_api
            current_path = Path(__file__).parent.parent

        version_file = current_path / ".app-version"
        if version_file.exists():
            version_content = version_file.read_text(encoding="utf-8").strip()
            if version_content:
                return version_content

        logger.debug("No .app-version file found or file is empty")
        return None

    except Exception as e:
        logger.debug("Failed to read version from .app-version file", exc_info=e)
        return None
