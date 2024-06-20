(lang dune 3.15)
(name opam2nix)

(formatting (enabled_for dune))
(generate_opam_files true)

(source (github timbertson/opam2nix))
(license "MIT")
(authors "Tim Cuthbertson <tim@gfxmonk.net>")
(maintainers "Tim Cuthbertson <tim@gfxmonk.net>")

(package
 (name opam2nix)
 (synopsis "Generate nix expressions from opam packages")
 (depends
  (ocaml (>= 4.11))
  base-unix
  dune-build-info
  fileutils
  lwt
  (lwt_ppx (>= 2.1.0))
  ocurl
  opam-0install
  (opam-state (>= 2.1.0))
  ppx_deriving
  ppx_deriving_yojson
  yojson
  (ounit2 :with-test)))
