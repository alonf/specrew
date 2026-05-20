# Retro: PSGallery Unsigned Default

This bug-fix slice stayed appropriately small and direct: prior investigation had already isolated the broken trust model, so removing Authenticode signing from the live PSGallery path restored the default install experience without reopening certificate-strategy design. The main lesson is that release trust assumptions must be validated on a fresh client path, not inferred from a successful publish workflow or from installs that rely on `-SkipPublisherCheck`.
