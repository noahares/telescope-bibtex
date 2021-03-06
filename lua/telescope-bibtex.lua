local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local actions = require('telescope.actions')
local conf = require('telescope.config').values

local function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

local function read_file(file)
  local entries = {}
  if not file_exists(file) then return {} end
  for line in io.lines(file) do
    if line:match("@%w*{") then
      local entry = line:gsub("@%w*{", "")
      entry = entry:sub(1, -2)
      entries[#entries + 1] = entry
    end
  end
  return entries
end

local function bibtex_picker(opts)
  local directory = io.popen('find . -maxdepth 1 -type f -name "*.bib"')
  local references = {}
  for file in directory:lines() do
    table.insert(references, file:sub(3))
  end
  directory:close()
  opts = opts or {}
  local results = {}
  for _, r in pairs(references) do
    local result = read_file(r)
    for _, entry in pairs(result) do
      table.insert(results, entry)
    end
  end
  pickers.new(opts, {
    prompt_title = 'Bibtex References',
    finder = finders.new_table {
      results = results,
      entry_maker = function(line)
        return {
          value = line,
          ordinal = line,
          display = line
        }
      end
    },
    previewer = nil,
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions._goto_file_selection:replace(function(_, _)
        local entry = "\\cite{"..actions.get_selected_entry().value.."}"
        actions.close(prompt_bufnr)
        vim.api.nvim_put({entry}, "", true, true)
        -- TODO: prettier insert mode? <16-01-21, @noahares> --
        vim.api.nvim_feedkeys("A", "n", true)
      end)
      return true
    end,
  }):find()
end

return {
  bibtex_picker = bibtex_picker
}
