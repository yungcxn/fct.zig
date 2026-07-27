const std = @import("std");

const compose_manual = @import("../point_free.zig").compose_manual;
const compose_auto = @import("../point_free.zig").compose_auto;
const post_free_manual = @import("../point_free.zig").post_free_manual;
const post_free_auto = @import("../point_free.zig").post_free_auto;
const id = @import("../point_free.zig").id;
const tap = @import("../point_free.zig").tap;
const field = @import("../point_free.zig").field;

const bind0 = @import("../func_manip.zig").bind0;
const bind = @import("../func_manip.zig").bind;
const bind_i = @import("../func_manip.zig").bind_i;
const curry = @import("../func_manip.zig").curry;

const map = @import("../seq_produce.zig").map;
const filter = @import("../seq_produce.zig").filter;
const filter_comptimef = @import("../seq_produce.zig").filter_comptimef;
const take = @import("../seq_produce.zig").take;
const partition = @import("../seq_produce.zig").partition;

const zip = @import("../muldseq_produce.zig").zip;
const zip_comptimef = @import("../muldseq_produce.zig").zip_comptimef;

const reduce = @import("../sval_produce.zig").reduce;
const any = @import("../sval_produce.zig").any;
const all = @import("../sval_produce.zig").all;
const find = @import("../sval_produce.zig").find;

// TODO NEXT
