;;;; Personal Autolith configuration, evaluated in the AUTOLITH package.

;;; OmniRoute fronts the Claude Code, Antigravity and other subscriptions on this host.
;;; Store its API key once with `autolith auth omniroute`; `(models :provider "omniroute")`
;;; refreshes the list after connecting a provider in the dashboard.
(register-openai-compatible-provider
 :name            "omniroute"
 :description     "OmniRoute"
 :endpoint        "http://127.0.0.1:20128/v1/chat/completions"
 :models-endpoint "http://127.0.0.1:20128/v1/models")
