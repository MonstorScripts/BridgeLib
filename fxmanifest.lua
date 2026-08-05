fx_version("cerulean")
game("gta5")
lua54("yes")

author("Alivemonstor")
description("Resource agnostic bridge layer, consumed through ox_lib require")
version("0.5.0")

files({
	"init.lua",
	"versions.lua",
	"modules/**/*.lua",
	"providers/**/*.lua",
})
