local eq = MiniTest.expect.equality
local ref = function(screenshot)
    -- ignore the last, 24th line on the screen as it has differing `screenattr` values between stable and nightly
    MiniTest.expect.reference_screenshot(screenshot, nil, { ignore_attr = { 24 } })
end

local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set()
T["nes"] = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.restart({ "-u", "scripts/minimal_init.lua" })
            child.lua_func(function()
                vim.g.copilot_nes_debounce = 450
                vim.lsp.config("copilot_ls", {
                    cmd = require("tests.mock_lsp").server,
                })
                vim.lsp.enable("copilot_ls")
            end)
        end,
        post_once = child.stop,
    },
})

T["nes"]["lsp starts"] = function()
    child.cmd("edit tests/fixtures/sameline_edit.txt")
    local lsp_count = child.lua_func(function()
        local count = 0
        local clients = vim.lsp.get_clients()
        for _, _ in pairs(clients) do
            --NOTE: #clients doesn't work, so we count in the loop
            count = count + 1
        end
        return count
    end)
    eq(lsp_count, 1)
end

T["nes"]["same line edit"] = function()
    child.cmd("edit tests/fixtures/sameline_edit.txt")
    ref(child.get_screenshot())
    vim.uv.sleep(500)
    child.lua_func(function()
        local copilot = vim.lsp.get_clients()[1]
        require("copilot-lsp.nes").request_nes(copilot)
    end)
    vim.uv.sleep(500)
    ref(child.get_screenshot())
    child.lua_func(function()
        local _ = require("copilot-lsp.nes").apply_pending_nes() and require("copilot-lsp.nes").walk_cursor_end_edit()
    end)
    ref(child.get_screenshot())
end

T["nes"]["multi line edit"] = function()
    child.cmd("edit tests/fixtures/multiline_edit.txt")
    ref(child.get_screenshot())
    vim.uv.sleep(500)
    child.lua_func(function()
        local copilot = vim.lsp.get_clients()[1]
        require("copilot-lsp.nes").request_nes(copilot)
    end)
    vim.uv.sleep(500)
    ref(child.get_screenshot())
    child.lua_func(function()
        local _ = require("copilot-lsp.nes").apply_pending_nes() and require("copilot-lsp.nes").walk_cursor_end_edit()
    end)
    ref(child.get_screenshot())
end

T["nes"]["removal edit"] = function()
    child.cmd("edit tests/fixtures/removal_edit.txt")
    ref(child.get_screenshot())
    vim.uv.sleep(500)
    child.lua_func(function()
        local copilot = vim.lsp.get_clients()[1]
        require("copilot-lsp.nes").request_nes(copilot)
    end)
    vim.uv.sleep(500)
    ref(child.get_screenshot())
    child.lua_func(function()
        require("copilot-lsp.nes").walk_cursor_start_edit()
    end)
    ref(child.get_screenshot())
    child.lua_func(function()
        local _ = require("copilot-lsp.nes").apply_pending_nes() and require("copilot-lsp.nes").walk_cursor_end_edit()
    end)
    ref(child.get_screenshot())
end

T["nes"]["add only edit"] = function()
    child.cmd("edit tests/fixtures/addonly_edit.txt")
    ref(child.get_screenshot())
    vim.uv.sleep(500)
    child.lua_func(function()
        local copilot = vim.lsp.get_clients()[1]
        require("copilot-lsp.nes").request_nes(copilot)
    end)
    vim.uv.sleep(500)
    ref(child.get_screenshot())
    child.lua_func(function()
        require("copilot-lsp.nes").walk_cursor_start_edit()
    end)
    vim.uv.sleep(100)
    ref(child.get_screenshot())
    child.lua_func(function()
        local _ = require("copilot-lsp.nes").apply_pending_nes() and require("copilot-lsp.nes").walk_cursor_end_edit()
    end)
    ref(child.get_screenshot())
end

T["nes"]["highlights replacement"] = function()
    child.cmd("edit tests/fixtures/highlight_test.c")
    child.lua_func(function()
        vim.cmd([[colorscheme vim]])
        vim.treesitter.start(0)
        vim.cmd([[hi! CopilotLspNesAdd guifg=NONE guibg=NONE]])
        vim.cmd([[hi! CopilotLspNesDelete guifg=NONE guibg=NONE]])
    end)
    ref(child.get_screenshot())
    vim.uv.sleep(500)
    child.lua_func(function()
        local copilot = vim.lsp.get_clients()[1]
        require("copilot-lsp.nes").request_nes(copilot)
    end)
    vim.uv.sleep(500)
    ref(child.get_screenshot())
    child.lua_func(function()
        local _ = require("copilot-lsp.nes").apply_pending_nes() and require("copilot-lsp.nes").walk_cursor_end_edit()
    end)
    ref(child.get_screenshot())
end
return T
