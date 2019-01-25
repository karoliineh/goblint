open CompareAST
open Cil
open Serialize

type commitID = string

let updateMap (oldFile: Cil.file) (newFile: Cil.file) (newCommitID: commitID) (ht: (string, Cil.fundec * commitID) Hashtbl.t) = 
    let assocList = compareCilFiles oldFile newFile in
    List.iter (fun (fundec: fundec) ->  Hashtbl.replace ht fundec.svar.vname (fundec, newCommitID)) assocList;
    ht


let create_map (new_file: Cil.file) (commit: commitID) =
    let add_to_hashtbl tbl (global: Cil.global) =
        match global with
            | Cil.GFun (fund, loc) ->
              Hashtbl.replace tbl fund.svar.vname (fund, commit) 
            | other -> ()
    in
    let tbl : (string, Cil.fundec * commitID) Hashtbl.t = Hashtbl.create 1000 in
    Cil.iterGlobals new_file (add_to_hashtbl tbl);
    tbl

(** For debugging purposes: print the mapping from function name to commit *)
let print_mapping (function_name: string) (dec, commit: Cil.fundec * commitID) =
  print_string function_name;
  print_string " -> ";
  print_endline commit

(** load the old cil.file, load the corresponding map, update the map, return it-
    restoreMap glob_folder old_file new_file *)
let restoreMap (folder: string) (old_commit: commitID) (new_commit: commitID) (oldFile: Cil.file) (newFile: Cil.file)= 
    let commitFolder = Filename.concat folder old_commit in
    let versionFile = Filename.concat commitFolder versionMapFilename in
    let oldMap = Serialize.unmarshall versionFile in
   (* let astFile = Filename.concat commitFolder Serialize.cilFileName in
    let oldAST = Cil.loadBinaryFile astFile in *)
    let updated = updateMap oldFile newFile new_commit oldMap in
    Hashtbl.iter print_mapping updated;
    updated

let restore_map (src_files: string list) (folder: string) (old_file: Cil.file) (new_file: Cil.file) =
    match Serialize.current_commit src_files with 
    |Some new_commit -> 
      (match Serialize.last_analyzed_commit src_files with
        |Some old_commit -> restoreMap folder old_commit new_commit old_file new_file 
        |None -> raise (Failure "No commit has been analyzed yet. Restore map failed."))
    |None -> raise (Failure "Working directory is dirty. Restore map failed.")