_: _final: prev: {
  efitools = prev.efitools.overrideAttrs (old: {
    # Fix for GCC 15 / C23 where 'bool', 'true', 'false' are keywords.
    # The nixpkgs patch removes `typedef bool` but doesn't add <stdbool.h>.
    # We need both: -std=gnu17 (to avoid C23 keywords) AND <stdbool.h> (to define bool).
    postPatch =
      (old.postPatch or "")
      + ''
        # Inject -std=gnu17 into Make.rules for EFI builds
        sed -i 's/^CFLAGS\s*=/CFLAGS = -std=gnu17 /' Make.rules

        # Add stdbool.h to files that use 'bool' type
        for f in lib/asn1/typedefs.h lib/asn1/chunk.h lib/asn1/enumerator.h lib/asn1/asn1_parser.h; do
          if [ -f "$f" ]; then
            sed -i '1i #include <stdbool.h>' "$f"
          fi
        done
      '';
  });
}
