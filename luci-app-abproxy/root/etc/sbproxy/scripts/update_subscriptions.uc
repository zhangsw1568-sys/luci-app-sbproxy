#!/usr/bin/ucode
'use strict';

import { open } from 'fs';
import { cursor } from 'uci';
import {
	decodeBase64Str, isEmpty, parseURL
} from '/etc/sbproxy/scripts/sbproxy.uc';

const uci = cursor();
const uciconfig = 'sbproxy';
uci.load(uciconfig);

const sub = uci.get_all(uciconfig, 'main') || {};
const url = sub.url;
if (!sub.enabled || isEmpty(url))
	exit(0);

function log(msg) {
	system('mkdir -p /var/run/sbproxy');
	let f = open('/var/run/sbproxy/subscription.log', 'a');
	f.write(msg + '\n');
	f.close();
}

function fetch(url) {
	system('/usr/bin/uclient-fetch -O /tmp/sbproxy_sub.txt "' + url + '"');
	let f = open('/tmp/sbproxy_sub.txt', 'r');
	let s = f.read('all');
	f.close();
	return s;
}

function add_node(name, cfg) {
	uci.set(uciconfig, name, 'node');
	for (let k in keys(cfg))
		uci.set(uciconfig, name, k, cfg[k]);
}

function clear_old_sub_nodes() {
	uci.foreach(uciconfig, 'node', (s) => {
		if ((s['.name'] ~ /^sub_/))
			uci.delete(uciconfig, s['.name']);
	});
}

function parse_line(line) {
	let scheme = split(line, '://', 2)[0];

	if (scheme == 'ss') {
		let rest = split(line, '://', 2)[1];
		let hash_parts = split(rest, '#', 2);
		let core = hash_parts[0];
		let label = hash_parts[1] || 'ss-node';
		let core_user = split(core, '@', 1)[0];
		let decoded = decodeBase64Str(core_user);
		if (!decoded)
			return null;
		let parts = split(decoded, ':', 2);
		let hostport = split(core, '@', 2)[1];
		let hp = split(hostport, ':', 2);
		return {
			label: label,
			type: 'shadowsocks',
			server: hp[0],
			server_port: hp[1],
			method: parts[0],
			password: parts[1],
			tls: '0',
			enabled: '1'
		};
	}

	if (scheme == 'trojan') {
		let u = parseURL('http://' + split(line, '://', 2)[1]);
		if (!u) return null;
		return {
			label: u.hash || 'trojan-node',
			type: 'trojan',
			server: u.hostname,
			server_port: u.port,
			password: u.username,
			tls: '1',
			server_name: u.searchParams.sni,
			enabled: '1'
		};
	}

	if (scheme == 'vless') {
		let u = parseURL('http://' + split(line, '://', 2)[1]);
		if (!u) return null;
		return {
			label: u.hash || 'vless-node',
			type: 'vless',
			server: u.hostname,
			server_port: u.port,
			uuid: u.username,
			tls: (u.searchParams.security in ['tls', 'reality']) ? '1' : '0',
			server_name: u.searchParams.sni,
			reality_public_key: u.searchParams.pbk,
			reality_short_id: u.searchParams.sid,
			transport: u.searchParams.type,
			path: u.searchParams.path,
			host: u.searchParams.host,
			service_name: u.searchParams.serviceName,
			enabled: '1'
		};
	}

	if (scheme == 'tuic' || scheme == 'hy2' || scheme == 'hysteria2') {
		let u = parseURL('http://' + split(line, '://', 2)[1]);
		if (!u) return null;
		return {
			label: u.hash || scheme + '-node',
			type: (scheme == 'tuic') ? 'tuic' : 'hysteria2',
			server: u.hostname,
			server_port: u.port,
			uuid: u.username,
			password: u.password,
			tls: '1',
			server_name: u.searchParams.sni,
			up_mbps: u.searchParams.upmbps || u.searchParams.up,
			down_mbps: u.searchParams.downmbps || u.searchParams.down,
			congestion_control: u.searchParams.congestion_control,
			enabled: '1'
		};
	}

	return null;
}

let raw = fetch(url);
if (isEmpty(raw))
	exit(1);

let decoded = decodeBase64Str(trim(raw));
let lines = split(trim(decoded || raw), '\n');

clear_old_sub_nodes();

let idx = 0;
for (let line in lines) {
	line = trim(line);
	if (isEmpty(line))
		continue;
	let cfg = parse_line(line);
	if (!cfg)
		continue;
	let name = 'sub_' + idx;
	add_node(name, cfg);
	idx++;
}

uci.commit(uciconfig);
log('Imported ' + idx + ' nodes.');
