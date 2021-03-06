(*
 * Copyright (c) 2011 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

type id = string

type t  = {
  id: id;
(*   fd: (int * Io_page.t) Lwt_stream.t; *)
  fd_read : Io_page.t Lwt_condition.t;
  fd_read_ret : unit Lwt_condition.t;
  fd_write: unit Lwt_condition.t;
  mutable active: bool;
  mac: string;
} 

val listen : t -> (Io_page.t -> unit Lwt.t) -> unit Lwt.t
val destroy : t -> unit Lwt.t

val write : t -> Io_page.t -> unit Lwt.t
val writev : t -> Io_page.t list -> unit Lwt.t

val create : ?dev:(string option) -> (id -> t -> unit Lwt.t) -> unit Lwt.t
val get_writebuf: t -> Io_page.t Lwt.t

val mac : t -> string 
val ethid : t -> id
