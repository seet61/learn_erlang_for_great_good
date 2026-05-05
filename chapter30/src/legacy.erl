-module(legacy).
-export([
    hash_password/2,
    verify_password/3
]).

hash_password(Password, Salt) ->
    PwdBin = unicode:characters_to_binary(Password),
    SaltBin = unicode:characters_to_binary(Salt),
    Combined = <<SaltBin/binary, PwdBin/binary>>,
    %Combined = <<PwdBin/binary, SaltBin/binary>>,
    Hash = crypto:hash(sha, Combined),
    binary:encode_hex(Hash, lowercase).

verify_password(Password, Salt, StoredPassword) ->
    hash_password(Password, Salt) == unicode:characters_to_binary(StoredPassword).
