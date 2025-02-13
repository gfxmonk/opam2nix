let with_temp_file : 'a. ((string * out_channel) -> 'a Lwt.t) -> 'a Lwt.t = fun fn ->
  let (path, out_channel) = Filename.open_temp_file "opam2nix-" "" in
  Lwt.finalize
    (fun () -> fn (path, out_channel))
    (fun () -> Lwt.return (
      if Sys.getenv_opt "OPAM2NIX_LEAVE_TMP" = Some "true"
        then ()
        else Unix.unlink path
    ))

