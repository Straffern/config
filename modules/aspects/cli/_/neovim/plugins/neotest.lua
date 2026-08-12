return {
  "nvim-neotest/neotest",
  opts = {
    quickfix = {
      open = function()
        if LazyVim.has("trouble.nvim") then
          require("trouble").open({ mode = "qflist", focus = false })
        else
          vim.cmd("copen")
        end
      end,
    },
  },
}
