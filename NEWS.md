# 0.6.0

## Breaking changes

- Swtich to Julia 0.7
- Because of changes to Julia's own `reinterpret`, ImageCore now
  defines and exports `reinterpretc` for reinterpreting
        numeric arrays <----> colorant arrays (#52)
- The ColorView and ChannelView types are deleted; their functionality
  is now handled via `reinterpret` (#52)
