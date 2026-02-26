-- -- THIS IS NOT THE ENTIRE TEMPLATE FILE
-- -- To see why, continue reading below...
-- require('base16-colorscheme').setup({
--   base00 = "{{colors.background.default.hex}}",
--   base01 = "{{colors.surface_container_lowest.default.hex}}",
--   base02 = "{{colors.surface_container_low.default.hex}}",
--   base03 = "{{colors.outline_variant.default.hex}}",
--   base04 = "{{colors.on_surface_variant.default.hex}}",
--   base05 = "{{colors.on_surface.default.hex}}",
--   base06 = "{{colors.inverse_on_surface.default.hex}}",
--   base07 = "{{colors.surface_bright.default.hex}}",
--   base08 = "{{colors.tertiary.default.hex | lighten: -5}}",
--   base09 = "{{colors.tertiary.default.hex}}",
--   base0A = "{{colors.secondary.default.hex}}",
--   base0B = "{{colors.primary.default.hex}}",
--   base0C = "{{colors.tertiary_container.default.hex}}",
--   base0D = "{{colors.primary_container.default.hex}}",
--   base0E = "{{colors.secondary_container.default.hex}}",
--   base0F = "{{colors.secondary.default.hex | lighten: -10}}",
-- })

-- Vibrant base16 color palette for matugen
require('base16-colorscheme').setup({
  -- Backgrounds (keep these subtle)
  base00 = "{{colors.background.default.hex}}",
  base01 = "{{colors.surface_container.default.hex}}",
  base02 = "{{colors.surface_container_high.default.hex}}",
  base03 = "{{colors.outline.default.hex}}",
  
  -- Foregrounds
  base04 = "{{colors.on_surface_variant.default.hex}}",
  base05 = "{{colors.on_surface.default.hex}}",
  base06 = "{{colors.on_primary_container.default.hex}}",
  base07 = "{{colors.surface_bright.default.hex}}",
  
  -- Vibrant accent colors
  base08 = "{{colors.error.default.hex}}",              -- Red (errors, deletion)
  base09 = "{{colors.tertiary.default.hex}}", -- Orange (constants, numbers)
  base0A = "{{colors.secondary.default.hex}}", -- Yellow (warnings, classes)
  base0B = "{{colors.primary.default.hex}}",    -- Green (strings, additions)
  base0C = "{{colors.tertiary.default.hex}}",          -- Cyan (regex, escape chars)
  base0D = "{{colors.primary.default.hex}}",           -- Blue (functions, keywords)
  base0E = "{{colors.secondary.default.hex}}",         -- Magenta (variables, tags)
  base0F = "{{colors.error.default.hex}}", -- Brown (deprecated, special)
})