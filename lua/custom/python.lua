-- ~/.config/nvim/lua/custom/python.lua

local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup('PythonVenvSetup', { clear = true })
  
  -- Dedicated log file inside Neovim's standard state directory
  local log_file = vim.fn.stdpath('state') .. '/python_setup.log'

  -- File-only logger (safe for asynchronous fast event callbacks)
  local function log(msg)
    local time = os.date('%Y-%m-%d %H:%M:%S')
    local f = io.open(log_file, 'a')
    if f then
      f:write(string.format('[%s] %s\n', time, msg))
      f:close()
    end
  end

  local function configure_lsp_client(client, bufnr, venv_python, extra_paths)
    if client.name == 'basedpyright' or client.name == 'pyright' then
      local new_settings = {
        python = {
          pythonPath = venv_python,
          analysis = {
            extraPaths = extra_paths,
            autoSearchPaths = true,
            useLibraryCodeForTypes = true,
          },
        },
      }

      client.config.settings = vim.tbl_deep_extend('force', client.config.settings or {}, new_settings)
      client.settings = client.config.settings

      client:notify('workspace/didChangeConfiguration', { settings = client.settings })
      log('Configured LSP client (' .. client.name .. ') with pythonPath: ' .. venv_python)
    end
  end

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'python',
    group = group,
    callback = function(args)
      local cwd = vim.fn.getcwd()
      local venv_path = cwd .. '/.venv'
      local venv_python = venv_path .. '/bin/python'

      log('FileType autocmd triggered for CWD: ' .. cwd)

      if vim.fn.executable('uv') == 0 then
        log('ERROR: "uv" executable not found in PATH')
        return
      end

      local pyprojects = vim.fn.globpath(cwd, '**/pyproject.toml', false, true)
      local requirements = vim.fn.globpath(cwd, '**/requirements.txt', false, true)

      local extra_paths = { cwd }

      if #pyprojects > 0 or #requirements > 0 then
        local function setup_deps()
          if #pyprojects > 0 then
            for _, pyproject_path in ipairs(pyprojects) do
              local pyproject_dir = vim.fn.fnamemodify(pyproject_path, ':h')
              table.insert(extra_paths, pyproject_dir)
              table.insert(extra_paths, vim.fn.fnamemodify(pyproject_dir, ':h'))

              log('Running: uv pip install -e ' .. pyproject_dir)
              vim.system({ 'uv', 'pip', 'install', '--python', venv_python, '-e', pyproject_dir }, {}, function(obj)
                if obj.code == 0 then
                  log('Successfully installed editable package from ' .. pyproject_dir)
                  vim.schedule(function()
                    local clients = vim.lsp.get_clients({ bufnr = args.buf })
                    for _, client in ipairs(clients) do
                      configure_lsp_client(client, args.buf, venv_python, extra_paths)
                    end
                  end)
                else
                  log('ERROR installing package from ' .. pyproject_dir .. ':\n' .. (obj.stderr or ''))
                end
              end)
            end
          elseif #requirements > 0 then
            local cmd = { 'uv', 'pip', 'install', '--python', venv_python }
            for _, req in ipairs(requirements) do
              table.insert(cmd, '-r')
              table.insert(cmd, req)
            end
            log('Running uv pip install for requirements.txt files...')
            vim.system(cmd, {}, function(obj)
              if obj.code == 0 then
                log('Successfully installed requirements.txt!')
                vim.schedule(function()
                  local clients = vim.lsp.get_clients({ bufnr = args.buf })
                  for _, client in ipairs(clients) do
                    configure_lsp_client(client, args.buf, venv_python, extra_paths)
                  end
                end)
              else
                log('ERROR installing requirements.txt:\n' .. (obj.stderr or ''))
              end
            end)
          end
        end

        if vim.fn.isdirectory(venv_path) == 0 then
          log('Creating .venv with uv at ' .. venv_path)
          vim.system({ 'uv', 'venv', venv_path }, {}, function(obj)
            if obj.code == 0 then
              log('.venv created successfully!')
              vim.schedule(setup_deps)
            else
              log('ERROR creating .venv:\n' .. (obj.stderr or ''))
            end
          end)
        else
          log('Existing .venv found at ' .. venv_path)
          setup_deps()
        end
      end

      if vim.fn.isdirectory(venv_path) == 1 then
        local clients = vim.lsp.get_clients({ bufnr = args.buf })
        for _, client in ipairs(clients) do
          configure_lsp_client(client, args.buf, venv_python, extra_paths)
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = group,
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client then return end

      local cwd = vim.fn.getcwd()
      local venv_python = cwd .. '/.venv/bin/python'

      if vim.fn.executable(venv_python) == 1 then
        local pyprojects = vim.fn.globpath(cwd, '**/pyproject.toml', false, true)
        local extra_paths = { cwd }

        for _, pyproject_path in ipairs(pyprojects) do
          local pyproject_dir = vim.fn.fnamemodify(pyproject_path, ':h')
          table.insert(extra_paths, pyproject_dir)
          table.insert(extra_paths, vim.fn.fnamemodify(pyproject_dir, ':h'))
        end

        log('LspAttach event triggered for client: ' .. client.name)
        configure_lsp_client(client, args.buf, venv_python, extra_paths)
      end
    end,
  })
end

return M
