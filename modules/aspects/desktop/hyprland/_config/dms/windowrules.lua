-- DMS Window Rules — managed by DankMaterialShell
-- Do not edit manually; changes may be overwritten

-- DMS-RULE: id=dms-floating-windows, name=DMS Floating Windows
hl.window_rule({ match = { class = "^com.danklinux.dms$" }, float = true })

-- DMS-RULE: id=wr_1790746336051536446, name=footclient
hl.window_rule({ match = { class = "^footclient$" }, opacity = 0.84 })
