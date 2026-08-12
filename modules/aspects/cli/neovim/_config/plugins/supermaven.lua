local function read_file(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end
	local content = file:read("*a")
	file:close()
	return content:gsub("%s+$", "")
end

local function dirname(path)
	return path:match("^(.*)/[^/]+$") or "."
end

local function write_file(path, content)
	vim.fn.mkdir(dirname(path), "p")
	local file = assert(io.open(path, "w"))
	file:write(content)
	file:close()
end

local function join(base, path)
	if path:sub(1, 1) == "/" then
		return path
	end
	return vim.fs.normalize(base .. "/" .. path)
end

local function probe_dir()
	local buffer_name = vim.api.nvim_buf_get_name(0)
	if buffer_name ~= "" then
		local stat = vim.uv.fs_stat(buffer_name)
		if stat and stat.type == "directory" then
			return buffer_name
		end
		return dirname(buffer_name)
	end
	return vim.fn.getcwd()
end

local function jj_git_env()
	local result = vim.system({ "jj", "root" }, { text = true, cwd = probe_dir() }):wait()
	if result.code ~= 0 then
		return nil
	end

	local jj_root = vim.trim(result.stdout)
	if jj_root == "" then
		return nil
	end

	local git_stat = vim.uv.fs_stat(jj_root .. "/.git")
	if git_stat and git_stat.type == "directory" then
		return nil
	end

	local repo_path = jj_root .. "/.jj/repo"
	local repo_stat = vim.uv.fs_stat(repo_path)
	if not repo_stat then
		return nil
	end
	if repo_stat.type == "file" then
		repo_path = join(dirname(repo_path), read_file(repo_path))
	end

	local store_path = repo_path .. "/store"
	local git_target_path = store_path .. "/git_target"
	local git_target = read_file(git_target_path)
	local git_dir = git_target and join(store_path, git_target) or (store_path .. "/git")
	if not vim.uv.fs_stat(git_dir) then
		return nil
	end

	return {
		GIT_DIR = git_dir,
		JJ_REPO_PATH = repo_path,
		GIT_WORK_TREE = jj_root,
	}
end

local function env_list(env)
	local out = {}
	for key, value in pairs(env) do
		table.insert(out, key .. "=" .. tostring(value))
	end
	return out
end

local function add_dir(args, seen, path)
	if path == "" or path == "/" or seen[path] then
		return
	end
	local parent = dirname(path)
	if parent ~= path then
		add_dir(args, seen, parent)
	end
	table.insert(args, "--dir")
	table.insert(args, path)
	seen[path] = true
end

local function add_bind(args, seen, mode, source, dest)
	add_dir(args, seen, dirname(dest))
	table.insert(args, mode)
	table.insert(args, source)
	table.insert(args, dest)
end

local function bind_if_exists(args, seen, mode, path)
	if vim.uv.fs_stat(path) then
		add_bind(args, seen, mode, path, path)
	end
end

local function workspace_binds(args, seen, root)
	add_dir(args, seen, root)
	local scanner = vim.uv.fs_scandir(root)
	if not scanner then
		return
	end

	while true do
		local name = vim.uv.fs_scandir_next(scanner)
		if not name then
			break
		end
		if name ~= ".git" then
			local path = root .. "/" .. name
			add_bind(args, seen, "--bind", path, path)
		end
	end
end

local function supermaven_env(shim_path)
	local env = vim.fn.environ()
	env.PATH = shim_path .. ":" .. env.PATH

	local git_env = jj_git_env()
	if git_env then
		env.GIT_DIR = git_env.GIT_DIR
		env.GIT_WORK_TREE = git_env.GIT_WORK_TREE
		env.SUPERMAVEN_JJ_SHIM = "1"
	end

	return env, git_env
end

local function supermaven_spawn(binary_path, shim_path)
	local env, git_env = supermaven_env(shim_path)
	if not git_env then
		return binary_path, { "stdio" }, env_list(env)
	end

	local gitfile = vim.fn.stdpath("cache")
		.. "/supermaven-jj-git/"
		.. vim.fn.sha256(git_env.GIT_WORK_TREE)
		.. ".git"
	write_file(gitfile, "gitdir: " .. git_env.GIT_DIR .. "\n")

	local args = {}
	local seen = {}
	local bwrap = vim.g.supermaven_jj_bwrap_path or "bwrap"

	table.insert(args, "--ro-bind")
	table.insert(args, "/nix")
	table.insert(args, "/nix")
	table.insert(args, "--ro-bind")
	table.insert(args, "/etc")
	table.insert(args, "/etc")
	table.insert(args, "--dev")
	table.insert(args, "/dev")
	table.insert(args, "--proc")
	table.insert(args, "/proc")
	table.insert(args, "--tmpfs")
	table.insert(args, "/tmp")

	bind_if_exists(args, seen, "--bind", vim.env.HOME .. "/.supermaven")
	bind_if_exists(args, seen, "--bind", vim.env.HOME .. "/.local/share/supermaven")
	add_bind(args, seen, "--bind", git_env.JJ_REPO_PATH, git_env.JJ_REPO_PATH)
	add_bind(args, seen, "--bind", git_env.GIT_DIR, git_env.GIT_DIR)
	workspace_binds(args, seen, git_env.GIT_WORK_TREE)
	add_bind(args, seen, "--ro-bind", gitfile, git_env.GIT_WORK_TREE .. "/.git")

	table.insert(args, "--chdir")
	table.insert(args, probe_dir())
	table.insert(args, binary_path)
	table.insert(args, "stdio")

	return bwrap, args, env_list(env)
end

local function close_handle(handle)
	if handle and not handle:is_closing() then
		handle:close()
	end
end

return {
	{
		"supermaven-inc/supermaven-nvim",
		config = function()
			local shim_path = vim.g.supermaven_jj_git_shim_path
			if shim_path and shim_path ~= "" then
				local binary = require("supermaven-nvim.binary.binary_handler")
				local binary_fetcher = require("supermaven-nvim.binary.binary_fetcher")
				local log = require("supermaven-nvim.logger")
				local u = require("supermaven-nvim.util")

				binary.start_binary = function(self)
					local command, args, env = supermaven_spawn(binary_fetcher:fetch_binary(), shim_path)
					self.stdin = u.uv.new_pipe(false)
					self.stdout = u.uv.new_pipe(false)
					self.stderr = u.uv.new_pipe(false)
					self.last_text = nil
					self.last_path = nil
					self.last_context = nil
					self.wants_polling = false
					self.handle = u.uv.spawn(command, {
						args = args,
						stdio = { self.stdin, self.stdout, self.stderr },
						env = env,
					}, function(code)
						log:debug("sm-agent exited with code " .. code)
						close_handle(self.handle)
						self.handle = nil
					end)
					if not self.handle then
						log:debug("Starting binary")
					end
					self:read_loop()
					self:greeting_message()
				end
			end

			require("supermaven-nvim").setup({})
		end,
	},
}
