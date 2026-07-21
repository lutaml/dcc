# frozen_string_literal: true

# `Dcc::ContextConfiguration` mirrors the registry-aware per-major-version
# pattern from plurimath/mml. Each version module (`Dcc::V2`, `Dcc::V3`,
# `Dcc::Si::V1`, `Dcc::Si::V2`) extends this module and defines a unique
# `CONTEXT_ID` symbol (e.g. `:dcc_v3`). The version's Configuration then
# provides:
#
# * `register_model(klass, id:)` — register a model class for an XML element
#   name within this version's type registry.
# * `create_context(id:, substitutions:, ...)` — derive a custom context for
#   minor-version variants (e.g. `:dcc_v3_4`).
# * `populate_context!` — rebuild the version's built-in context (useful in
#   tests after clearing the global cache).
# * `default_context_id` — the context id that `parse` uses when no override
#   is supplied.
module Dcc
  module ContextConfiguration
    # @return [Symbol] the version's canonical context id (e.g. `:dcc_v3`).
    def context_id
      self::CONTEXT_ID
    end

    # @return [Lutaml::Model::Context, nil] the live context for this version,
    #   or `nil` if not yet populated.
    def context
      Lutaml::Model::GlobalContext.context(context_id)
    end

    # Create or replace a context. If `id` matches the version's canonical
    # context id, the built-in context is rebuilt via `populate_context!`.
    #
    # @param id [Symbol, String] context name.
    # @param registry [Lutaml::Model::TypeRegistry, nil] custom registry.
    # @param fallback_to [Array<Symbol>] fallback chain for type lookup.
    # @param substitutions [Array<Hash{from_type:, to_type:}>] type substitutions.
    def create_context(id:, registry: nil, fallback_to: [context_id], substitutions: [])
      normalized_id = ::Dcc::ContextOptions.normalize_context_reference(id)
      return populate_context! if normalized_id == context_id

      unregister_existing(normalized_id)
      create_type_context(
        id: normalized_id,
        registry: registry || Lutaml::Model::TypeRegistry.new,
        fallback_to: normalize_fallbacks(fallback_to),
        substitutions: substitutions,
      )
    end

    # Rebuild the version's built-in context from `registered_models`.
    def populate_context!
      unregister_existing(context_id)
      register_models_in(base_type_context)
    end

    # Contexts that this one falls back to when type lookup fails.
    # Override in version modules to pull in cross-namespace types
    # (e.g. DCC contexts fall back to D-SI contexts for `:real`, `:hybrid`).
    # @return [Array<Symbol>]
    def fallback_contexts
      [:default]
    end

    # Register a model for an XML element name and remember it for rebuilds.
    #
    # @param klass [Class] the model class.
    # @param id [Symbol, String] XML element local name (e.g. `:digitalCalibrationCertificate`).
    # @return [Class] the registered class.
    def register_model(klass, id:)
      normalized_id = id.to_sym
      registered_models[normalized_id] = klass
      (context || populate_base_context).registry.register(normalized_id, klass)
      clear_cache(klass)
      klass
    end

    # @return [Symbol] the context id used when none is supplied explicitly.
    def default_context_id
      @default_context_id || context_id
    end

    # Override the default context (used by `custom_models=`).
    attr_writer :default_context_id

    # Convenience: bulk-register model substitutions.
    #
    # @param models [Hash{Class => Class}] from_type => to_type.
    def custom_models=(models)
      substitutions = models.map do |from_type, to_type|
        { from_type: from_type, to_type: to_type }
      end
      create_context(id: :custom_models, substitutions: substitutions)
      @default_context_id = :custom_models
    end

    # Reset any custom default context.
    def clear_custom_models
      @default_context_id = nil
    end

    # Public read-only accessors for cross-context re-export.
    # @return [Array<Symbol>] ids registered in this context.
    def registered_model_ids
      registered_models.keys
    end

    # @param id [Symbol] the model id.
    # @return [Class, nil] the registered class.
    def registered_model_class(id)
      registered_models[id.to_sym]
    end

    private

    def unregister_existing(id)
      return unless Lutaml::Model::GlobalContext.context(id)

      Lutaml::Model::GlobalContext.unregister_context(id)
    end

    def populate_base_context
      base_type_context
    end

    def create_type_context(id:, registry:, fallback_to:, substitutions: [])
      Lutaml::Model::GlobalContext.create_context(
        id: id,
        registry: registry,
        fallback_to: fallback_to,
        substitutions: substitutions,
      ).tap { Lutaml::Model::GlobalContext.clear_caches }
    end

    def base_type_context
      create_type_context(
        id: context_id,
        registry: Lutaml::Model::TypeRegistry.new,
        fallback_to: fallback_contexts,
      )
    end

    def register_models_in(type_context)
      registered_models.each do |model_id, klass|
        type_context.registry.register(model_id, klass)
        clear_cache(klass)
      end
      Lutaml::Model::GlobalContext.clear_caches
      type_context
    end

    def normalize_fallbacks(fallback_to)
      Array(fallback_to).map { |f| ::Dcc::ContextOptions.normalize_context_reference(f) }
    end

    def registered_models
      @registered_models ||= {}
    end

    def clear_cache(klass)
      return unless klass.is_a?(Class)
      return unless klass < ::Lutaml::Model::Serializable
      return unless klass.method_defined?(:clear_cache)

      klass.clear_cache(context_id)
    end
  end
end
