# VCcURL

VCcURL - This is a useful package for Voxel Core designed to access the Internet and use various protocols before their official implementation in Voxel Core. 
The content pack provides various high-level functions for interacting with various protocols supported by the pack, such as:
**HTTP** VCcURL 1.0 >
**SMTP** VCCURL 1.2 >
 
Examples of use:

Synchronous **HTTP GET** request to [Voxel World API](https://voxelword.ru/api)
-# VCcURL 1.1
```lua
local info, head = http.get("voxelworld.ru/api/v1/mods",
	{
		responseType = "dirty_json",
		secured = true
	}
)
```

Synchronous **HTTP POST** request to [Catbox API](https://catbox.moe/tools.php)
-# VCcURL 1.1
```lua
local info, head = http.post("catbox.moe/user/api.php",
	{
		forms =
		{
			{ name = "reqtype", content = "fileupload" },
			{ name = "userhash" },
			{ type = "file", name = "fileToUpload", content = "world:world.json" }
		},
		secured = true
	}
)
```

Asynchronous **SMTP** request to [Gmail SMTP](https://smtp.gmail.com)
-# VCcURL 1.2
```lua
smpt.async.mail(
  "sender@gmail.com",
  "recipient@example.com",
  {
    server = "smtp.gmail.com:456", -- or server = "smtp.gmail.com", port = 456
    subject = "Example Message",
    forms =
    {
        { [''] = '(', type = "multipart/mixed" }
        { [''] = "This is a mail message", type = "text/plain" },
        { file = { type = "file", content = "example:message.html" }, type = "text/html", encoder = "base64" }
        { [''] = ')' }
    },
    pass = "API key",
    secured = true
  }
)
```

## Installation and use guide
[EN](docs/en/install&usage.md) 
[RU](docs/ru/install&usage.md)

## VCcURL API Documentation
[EN](docs/en/dev.md) 
[RU](docs/ru/dev.md)
