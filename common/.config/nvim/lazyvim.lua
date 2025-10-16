local nvim_config_path = vim.fn.stdpath('config')
vim.opt.rtp:append(nvim_config_path .. "/lazyvim")
require 'config.lazy'
