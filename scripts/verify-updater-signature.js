#!/usr/bin/env node
// Check that an updater signature verifies against the public key compiled
// into alloomi (apps/web/src-tauri/tauri.conf.json plugins.updater.pubkey).
//
// Usage: node scripts/verify-updater-signature.js "<pubkey>" <file>
//        (reads <file>.sig; exits 0 only when the signature is valid)
//
// Use it once after configuring the TAURI_SIGNING_PRIVATE_KEY secret to prove
// CI signs with the key the client trusts, and whenever a published artifact
// is in doubt. Signatures are minisign (Ed25519; "ED" = BLAKE2b-512
// prehashed), the same check tauri-plugin-updater performs, using only
// Node's built-in crypto.
const crypto = require("crypto"), fs = require("fs");
const [pubB64, file] = process.argv.slice(2);
const lineAfterComment = (text) => text.split("\n").find((l) => l && !l.startsWith("untrusted comment:"));
const pub = Buffer.from(lineAfterComment(Buffer.from(pubB64, "base64").toString()), "base64");
const sig = Buffer.from(lineAfterComment(Buffer.from(fs.readFileSync(file + ".sig", "utf8"), "base64").toString()), "base64");
if (!pub.subarray(2, 10).equals(sig.subarray(2, 10))) { console.error("key id mismatch: signed by a different key"); process.exit(1); }
const data = fs.readFileSync(file);
const msg = sig.subarray(0, 2).toString() === "ED" ? crypto.createHash("blake2b512").update(data).digest() : data;
const key = crypto.createPublicKey({ key: Buffer.concat([Buffer.from("302a300506032b6570032100", "hex"), pub.subarray(10)]), format: "der", type: "spki" });
const ok = crypto.verify(null, msg, key, sig.subarray(10, 74));
console.log(ok ? "signature OK" : "signature INVALID"); process.exit(ok ? 0 : 1);
