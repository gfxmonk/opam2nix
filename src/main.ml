open Printf
open Opam2nix
open Util

let commands : (string * (int -> string array -> unit)) list = [
	"invoke", Invoke.main;
	"resolve", Select.main;
	"extract", Extract.main;
	"version", fun _idx _args ->
			printf "opam2nix: %s\nopam: %s\n"
			(match Build_info.V1.version () with
			| None -> "n/a"
			| Some v -> Build_info.V1.Version.to_string v)
				OpamVersion.(to_string current)
]

let usage () =
	eprintf "Usage: opam2nix <command> [args]\n\nAvailable commands: %s.\n"
		(commands |> List.map (fun (name, _) -> name) |> String.concat ", ")
let () =
	if Array.length Sys.argv <= 1 then (
		usage ();
		exit 1
	) else (
		let commandName = Sys.argv.(1) in
		let command =
			try Some (commands |> List.find (fun (name, _action) -> name = commandName))
			with Not_found -> None in
		match command with
			| Some (_name, action) -> begin
					Printf.eprintf "+ %s\n" (Sys.argv |> Array.to_list |> String.concat " ");
					OpamStateConfig.update ~root_dir:(
						let open OpamFilename in
						let open Op in
						Dir.of_string (Filename.get_temp_dir_name ()) / "opam2nix"
					) ();
					try action 1 Sys.argv
					with Arg.Help err -> (prerr_string err; exit 1)
				end
			| None -> eprintf "Unknown command: %s\n" commandName; usage (); exit 1
	)
