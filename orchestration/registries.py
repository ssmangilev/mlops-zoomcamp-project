from typing import Callable, Dict


class ModelRegistry:
    def __init__(self):
        self._models = {}

    def register(self, name: str, model_class):
        """ Registers a model class with optional parameters. """
        if name in self._models:
            raise ValueError(f"Model with name '{name}' is already registered.")
        self._models[name] = {"model_class": model_class}

    def get(self, name: str):
        """ Retrieves the model class and parameters by name. """
        model_info = self._models.get(name)
        if model_info is None:
            raise ValueError(f"Model '{name}' not found in registry.")
        return model_info["model_class"], model_info["params"]

    def list_models(self):
        """ List all registered model names. """
        return list(self._models.keys())


class MetricRegistry:
    def __init__(self):
        self._registry: Dict[str, Callable] = {}

    def register(self, name: str, func: Callable):
        """Register a new metric function under a given name."""
        if name in self._registry:
            raise ValueError(f"Metric '{name}' is already registered.")
        self._registry[name] = func

    def get(self, name: str) -> Callable:
        """Retrieve a metric function by name."""
        if name not in self._registry:
            raise KeyError(f"Metric '{name}' is not registered.")
        return self._registry[name]

    def list_metrics(self) -> Dict[str, Callable]:
        """List all registered metrics."""
        return self._registry.copy()

    def has(self, name: str) -> bool:
        """Check if a metric is registered."""
        return name in self._registry


# Initialize the model registry at the module level
model_registry = ModelRegistry()


# Initialize the metric registry at the module level
metric_registry = MetricRegistry()
