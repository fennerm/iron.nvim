-- luacheck: globals insulate setup describe it assert mock
-- luacheck: globals before_each after_each
 local inspect = require('inspect')

insulate("About #iron functionality", function()

    local _ = require('iron.util.functional')
    before_each(function()
        _G.vim = mock({ api = {
                    nvim_call_function = function(_, _) return 1 end,
                    nvim_command = function(_) return "" end,
                    nvim_get_option = function(_) return "" end,
                    nvim_get_var = function(_) return "" end,
            }})

        _G.os = mock({
                execute = function(_) return 0 end,
            })
        end)

  after_each(function()
     package.loaded['iron'] = nil
     package.loaded['iron.core'] = nil
   end)

  describe("default #config", function()
    it("doesn't assume preferred values", function()
      local iron = require('iron')
      assert.are_same(iron.config.preferred.python, nil)
    end)

    it("has toggle #visibility enabled", function()
      local iron = require('iron')
      assert.are_same(iron.config.visibility, iron.predefs.visibility.toggle)
      end)
  end)

  describe("dynamic #config", function()
    it("is not called on a stored config", function()
      local iron = require('iron')
      iron.config.stuff = 1
      local _ = iron.config.stuff
      assert.stub(_G.vim.api.nvim_get_var).was_called(0)
    end)

    it("is called on a neovim variable", function()
      local iron = require('iron')
      local _ = iron.config.stuff
      assert.spy(_G.vim.api.nvim_call_function).was_called(1)
      assert.spy(_G.vim.api.nvim_call_function).was.called_with("exists", {"iron_stuff"})
      assert.spy(_G.vim.api.nvim_get_var).was.called(1)
      assert.spy(_G.vim.api.nvim_get_var).was.called_with("iron_stuff")
    end)
  end)

  describe("#memory related", function()
    it("get_repl", function()
      local iron = require('iron')
      local repl = iron.core.get_repl(iron.config, iron.memory, 'python')
      assert.are_same(#(_.keys(repl)), 3)
      assert.are_same(#(_.keys(iron.memory)), 1)
      assert.are_not_same(iron.memory.python, nil)
      assert.are_same(#(_.keys(iron.memory.python)), 1)
      assert.are_same(repl, iron.config.memory_management.get(iron.memory, 'python'))
    end)
  end)

  describe("#core functions", function()
    it("create_new_repl", function()
      local iron = require('iron')
      iron.core.get_preferred_repl = function(_, _, _)
        return {command = "x"}
      end
      iron.core.create_new_repl(iron.config, "python")
      assert.spy(_G.vim.api.nvim_command).was_called(1)
      assert.spy(_G.vim.api.nvim_call_function).was_called_with("exists", {"iron_repl_open_cmd"})
      assert.spy(_G.vim.api.nvim_call_function).was_called_with("termopen", {{"x"}})
    end)

    it("get_preferred_repl", function()
      local iron = require('iron')
      local fts = {python = {stuff = {command = "x"}}}
      local ret = iron.core.get_preferred_repl(iron.config, fts, "python")
      assert.spy(_G.os.execute).was_called(1)
      assert.spy(_G.os.execute).was_called_with('which stuff > /dev/null')
      assert.are_same(ret, {command = "x"})
    end)
  end)
end)
