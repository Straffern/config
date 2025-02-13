return {
  {
    "ibhagwan/fzf-lua",
    opts = {
      grep = {
        rg_glob = true,
        -- first returned string is the new search query
        -- second returned string are (optional) additional rg flags
        -- @return string, string?
        glob_flag = "--iglob", -- for case sensitive globs use '--glob'
        glob_separator = "%s%-%-", -- query separator pattern (lua): ' --'

        -- rg_glob_fn = function(query, opts)
        --   local regex, flags = query:match("^(.-)%s%-%-(.*)$")
        --   -- If no separator is detected will return the original query
        --   return (regex or query), flags
        -- end,
      },
    },
  },
}
