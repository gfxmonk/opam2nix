open Util
open OpamFile
module Version = OpamPackage.Version
module Name = OpamPackage.Name
module Seq = Seq_ext

let version_sep = "."

type spec = {
	github_owner: string;
	github_name: string;
	spec_commit: string option;
}

type t = {
	repo_key: string;
	spec: spec;
	(* TODO: OpamFilename.Dir.t? *)
	repo_path: string;
	repo_commit: string;
	(* returned as Lwt.t because it's needed lazily much later than commit and version *)
	repo_digest: Digest_cache.nix_digest Lwt.t;
}

type package = {
	repo: t;
	rel_path: string;
	package: OpamPackage.t;
	opam: OPAM.t;
	url: URL.t option;
}

type loaded_package = {
	loaded_opam: OPAM.t;
	repository_expr: unit -> Opam_metadata.opam_src Lwt.t;
	src_expr: Digest_cache.t -> (Nix_expr.t option, Digest_cache.error) Result.t Lwt.t;
	loaded_url: Opam_metadata.url option;
}

type direct_package = {
	direct_opam_relative: string;
	direct_opam: OPAM.t;
	direct_name: Name.t;
	direct_version: Version.t option;
}

(* low level pkg returned by lookup, which is all Extract module needs *)
type lookup_result = {
	p_package: OpamPackage.t;
	p_opam: OPAM.t;
	p_url: URL.t option;
}

let packages_dir = "packages"

let full_path pkg = Filename.concat pkg.repo.repo_path pkg.rel_path

let git_url spec = Printf.sprintf "https://github.com/%s/%s.git" spec.github_owner spec.github_name

let load_url path =
	if Sys.file_exists path then begin
		let url_file = open_in path in
		let rv = URL.read_from_channel url_file in
		close_in url_file;
		Some rv
	end else None

let _lookup = fun repo_path package -> (
	let pname = OpamPackage.Name.to_string (OpamPackage.name package) in
	let pver = OpamPackage.Version.to_string (OpamPackage.version package) in
	let rel_path =
		Filename.concat
			(Filename.concat packages_dir pname)
			(pname ^ version_sep ^ pver)
	in
	let full_path = Filename.concat repo_path rel_path in
	let opam_path = Filename.concat full_path "opam" in
	if Sys.file_exists opam_path then
		let opam = Opam_metadata.load_opam (opam_path) in
			Some (rel_path, {
				p_package = package;
				p_opam = opam;
				p_url = OPAM.url opam |> Option.or_else (load_url (Filename.concat full_path "url"));
			})
	else
		None
)

let lookup repo_path package = _lookup repo_path package |> Option.map snd

let _lookup_package_versions repo_path package = (
	debug "processing package %s\n" package;
	let package_base = Filename.concat packages_dir package in
	let package_abs = Filename.concat repo_path package_base in
	let list_versions () =
		debug "listing %s\n" package_abs;
		let dirs = try
			list_dirs package_abs
		with Sys_error e -> (
			debug "Skipping (%s)\n" e;
			[]
		)
		in
		dirs |> filter_map (without_leading (package ^ version_sep))
	in

	list_versions () |> List.filter_map (fun version ->
		let package = OpamPackage.create (Name.of_string package) (Version.of_string version) in
		_lookup repo_path package
	)
)

let lookup_package_versions repo_path package = _lookup_package_versions repo_path package |> List.map snd

let list_package repo package =
	_lookup_package_versions repo.repo_path package
	|> List.map (fun (rel_path, { p_package = package; p_opam = opam; p_url = url}) ->
		{ repo; rel_path; opam; package; url; }
	)
