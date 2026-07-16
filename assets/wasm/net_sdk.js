/* @ts-self-types="./net_sdk.d.ts" */

export class DartTransporter {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(DartTransporter.prototype);
        obj.__wbg_ptr = ptr;
        DartTransporterFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        DartTransporterFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_darttransporter_free(ptr, 0);
    }
    /**
     * @returns {Promise<NetResultStatus>}
     */
    close_all_transports() {
        const ret = wasm.darttransporter_close_all_transports(this.__wbg_ptr);
        return takeObject(ret);
    }
    /**
     * @param {number} transport_id
     * @returns {Promise<NetResultStatus>}
     */
    close_transport(transport_id) {
        const ret = wasm.darttransporter_close_transport(this.__wbg_ptr, transport_id);
        return takeObject(ret);
    }
    /**
     * @param {Function} callback
     * @returns {DartTransporter}
     */
    static create(callback) {
        const ret = wasm.darttransporter_create(addHeapObject(callback));
        return DartTransporter.__wrap(ret);
    }
    /**
     * @param {NetConfigRequestWasm} config
     * @returns {number}
     */
    create_transporter(config) {
        _assertClass(config, NetConfigRequestWasm);
        var ptr0 = config.__destroy_into_raw();
        const ret = wasm.darttransporter_create_transporter(this.__wbg_ptr, ptr0);
        return ret >>> 0;
    }
    /**
     * @param {Function} callback
     */
    constructor(callback) {
        const ret = wasm.darttransporter_create(addHeapObject(callback));
        this.__wbg_ptr = ret >>> 0;
        DartTransporterFinalization.register(this, this.__wbg_ptr, this);
        return this;
    }
    /**
     * @param {NetRequestWasm} request
     * @returns {Promise<NetResponseWasm>}
     */
    send_request(request) {
        _assertClass(request, NetRequestWasm);
        var ptr0 = request.__destroy_into_raw();
        const ret = wasm.darttransporter_send_request(this.__wbg_ptr, ptr0);
        return takeObject(ret);
    }
    /**
     * @returns {number}
     */
    version() {
        const ret = wasm.darttransporter_version(this.__wbg_ptr);
        return ret >>> 0;
    }
}
if (Symbol.dispose) DartTransporter.prototype[Symbol.dispose] = DartTransporter.prototype.free;

export class IntoUnderlyingByteSource {
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        IntoUnderlyingByteSourceFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_intounderlyingbytesource_free(ptr, 0);
    }
    /**
     * @returns {number}
     */
    get autoAllocateChunkSize() {
        const ret = wasm.intounderlyingbytesource_autoAllocateChunkSize(this.__wbg_ptr);
        return ret >>> 0;
    }
    cancel() {
        const ptr = this.__destroy_into_raw();
        wasm.intounderlyingbytesource_cancel(ptr);
    }
    /**
     * @param {ReadableByteStreamController} controller
     * @returns {Promise<any>}
     */
    pull(controller) {
        const ret = wasm.intounderlyingbytesource_pull(this.__wbg_ptr, addHeapObject(controller));
        return takeObject(ret);
    }
    /**
     * @param {ReadableByteStreamController} controller
     */
    start(controller) {
        wasm.intounderlyingbytesource_start(this.__wbg_ptr, addHeapObject(controller));
    }
    /**
     * @returns {ReadableStreamType}
     */
    get type() {
        const ret = wasm.intounderlyingbytesource_type(this.__wbg_ptr);
        return __wbindgen_enum_ReadableStreamType[ret];
    }
}
if (Symbol.dispose) IntoUnderlyingByteSource.prototype[Symbol.dispose] = IntoUnderlyingByteSource.prototype.free;

export class IntoUnderlyingSink {
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        IntoUnderlyingSinkFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_intounderlyingsink_free(ptr, 0);
    }
    /**
     * @param {any} reason
     * @returns {Promise<any>}
     */
    abort(reason) {
        const ptr = this.__destroy_into_raw();
        const ret = wasm.intounderlyingsink_abort(ptr, addHeapObject(reason));
        return takeObject(ret);
    }
    /**
     * @returns {Promise<any>}
     */
    close() {
        const ptr = this.__destroy_into_raw();
        const ret = wasm.intounderlyingsink_close(ptr);
        return takeObject(ret);
    }
    /**
     * @param {any} chunk
     * @returns {Promise<any>}
     */
    write(chunk) {
        const ret = wasm.intounderlyingsink_write(this.__wbg_ptr, addHeapObject(chunk));
        return takeObject(ret);
    }
}
if (Symbol.dispose) IntoUnderlyingSink.prototype[Symbol.dispose] = IntoUnderlyingSink.prototype.free;

export class IntoUnderlyingSource {
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        IntoUnderlyingSourceFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_intounderlyingsource_free(ptr, 0);
    }
    cancel() {
        const ptr = this.__destroy_into_raw();
        wasm.intounderlyingsource_cancel(ptr);
    }
    /**
     * @param {ReadableStreamDefaultController} controller
     * @returns {Promise<any>}
     */
    pull(controller) {
        const ret = wasm.intounderlyingsource_pull(this.__wbg_ptr, addHeapObject(controller));
        return takeObject(ret);
    }
}
if (Symbol.dispose) IntoUnderlyingSource.prototype[Symbol.dispose] = IntoUnderlyingSource.prototype.free;

export class NetConfigHttpWasm {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(NetConfigHttpWasm.prototype);
        obj.__wbg_ptr = ptr;
        NetConfigHttpWasmFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        NetConfigHttpWasmFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_netconfighttpwasm_free(ptr, 0);
    }
    /**
     * @param {NetHttpHeader[]} headers
     * @param {boolean} streaming
     * @returns {NetConfigHttpWasm}
     */
    static create(headers, streaming) {
        const ptr0 = passArrayJsValueToWasm0(headers, wasm.__wbindgen_export);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.netconfighttpwasm_create(ptr0, len0, streaming);
        return NetConfigHttpWasm.__wrap(ret);
    }
}
if (Symbol.dispose) NetConfigHttpWasm.prototype[Symbol.dispose] = NetConfigHttpWasm.prototype.free;

export class NetConfigRequestWasm {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(NetConfigRequestWasm.prototype);
        obj.__wbg_ptr = ptr;
        NetConfigRequestWasmFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        NetConfigRequestWasmFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_netconfigrequestwasm_free(ptr, 0);
    }
    /**
     * @param {string} url
     * @param {NetProtocol} protocol
     * @param {NetConfigHttpWasm} http
     * @param {StreamEncoding} encoding
     * @returns {NetConfigRequestWasm}
     */
    static create(url, protocol, http, encoding) {
        const ptr0 = passStringToWasm0(url, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len0 = WASM_VECTOR_LEN;
        _assertClass(http, NetConfigHttpWasm);
        var ptr1 = http.__destroy_into_raw();
        const ret = wasm.netconfigrequestwasm_create(ptr0, len0, protocol, ptr1, encoding);
        return NetConfigRequestWasm.__wrap(ret);
    }
}
if (Symbol.dispose) NetConfigRequestWasm.prototype[Symbol.dispose] = NetConfigRequestWasm.prototype.free;

export class NetHttpHeader {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(NetHttpHeader.prototype);
        obj.__wbg_ptr = ptr;
        NetHttpHeaderFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    static __unwrap(jsValue) {
        if (!(jsValue instanceof NetHttpHeader)) {
            return 0;
        }
        return jsValue.__destroy_into_raw();
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        NetHttpHeaderFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_nethttpheader_free(ptr, 0);
    }
    /**
     * @param {string} key
     * @param {string} value
     * @returns {NetHttpHeader}
     */
    static create(key, value) {
        const ptr0 = passStringToWasm0(key, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(value, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len1 = WASM_VECTOR_LEN;
        const ret = wasm.nethttpheader_create(ptr0, len0, ptr1, len1);
        return NetHttpHeader.__wrap(ret);
    }
    /**
     * @returns {string}
     */
    get key() {
        let deferred1_0;
        let deferred1_1;
        try {
            const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
            wasm.nethttpheader_key(retptr, this.__wbg_ptr);
            var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
            var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
            deferred1_0 = r0;
            deferred1_1 = r1;
            return getStringFromWasm0(r0, r1);
        } finally {
            wasm.__wbindgen_add_to_stack_pointer(16);
            wasm.__wbindgen_export4(deferred1_0, deferred1_1, 1);
        }
    }
    /**
     * @returns {string}
     */
    get value() {
        let deferred1_0;
        let deferred1_1;
        try {
            const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
            wasm.nethttpheader_value(retptr, this.__wbg_ptr);
            var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
            var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
            deferred1_0 = r0;
            deferred1_1 = r1;
            return getStringFromWasm0(r0, r1);
        } finally {
            wasm.__wbindgen_add_to_stack_pointer(16);
            wasm.__wbindgen_export4(deferred1_0, deferred1_1, 1);
        }
    }
}
if (Symbol.dispose) NetHttpHeader.prototype[Symbol.dispose] = NetHttpHeader.prototype.free;

export class NetHttpRetryConfig {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(NetHttpRetryConfig.prototype);
        obj.__wbg_ptr = ptr;
        NetHttpRetryConfigFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        NetHttpRetryConfigFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_nethttpretryconfig_free(ptr, 0);
    }
    /**
     * @param {number} max_retries
     * @param {Uint16Array} retry_status
     * @param {number} retry_delay
     * @returns {NetHttpRetryConfig}
     */
    static create(max_retries, retry_status, retry_delay) {
        const ptr0 = passArray16ToWasm0(retry_status, wasm.__wbindgen_export);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.nethttpretryconfig_create(max_retries, ptr0, len0, retry_delay);
        return NetHttpRetryConfig.__wrap(ret);
    }
}
if (Symbol.dispose) NetHttpRetryConfig.prototype[Symbol.dispose] = NetHttpRetryConfig.prototype.free;

/**
 * @enum {1 | 2 | 3 | 4}
 */
export const NetProtocol = Object.freeze({
    Http: 1, "1": "Http",
    Grpc: 2, "2": "Grpc",
    WebSocket: 3, "3": "WebSocket",
    Socket: 4, "4": "Socket",
});

export class NetRequestGrpcStream {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(NetRequestGrpcStream.prototype);
        obj.__wbg_ptr = ptr;
        NetRequestGrpcStreamFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        NetRequestGrpcStreamFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_netrequestgrpcstream_free(ptr, 0);
    }
    /**
     * @param {string} method
     * @param {Uint8Array} data
     * @returns {NetRequestGrpcStream}
     */
    static create(method, data) {
        const ptr0 = passStringToWasm0(method, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passArray8ToWasm0(data, wasm.__wbindgen_export);
        const len1 = WASM_VECTOR_LEN;
        const ret = wasm.netrequestgrpcstream_create(ptr0, len0, ptr1, len1);
        return NetRequestGrpcStream.__wrap(ret);
    }
}
if (Symbol.dispose) NetRequestGrpcStream.prototype[Symbol.dispose] = NetRequestGrpcStream.prototype.free;

export class NetRequestGrpcUnary {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(NetRequestGrpcUnary.prototype);
        obj.__wbg_ptr = ptr;
        NetRequestGrpcUnaryFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        NetRequestGrpcUnaryFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_netrequestgrpcunary_free(ptr, 0);
    }
    /**
     * @param {string} method
     * @param {Uint8Array} data
     * @returns {NetRequestGrpcUnary}
     */
    static create(method, data) {
        const ptr0 = passStringToWasm0(method, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passArray8ToWasm0(data, wasm.__wbindgen_export);
        const len1 = WASM_VECTOR_LEN;
        const ret = wasm.netrequestgrpcstream_create(ptr0, len0, ptr1, len1);
        return NetRequestGrpcUnary.__wrap(ret);
    }
}
if (Symbol.dispose) NetRequestGrpcUnary.prototype[Symbol.dispose] = NetRequestGrpcUnary.prototype.free;

export class NetRequestGrpcUnsubscribe {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(NetRequestGrpcUnsubscribe.prototype);
        obj.__wbg_ptr = ptr;
        NetRequestGrpcUnsubscribeFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        NetRequestGrpcUnsubscribeFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_netrequestgrpcunsubscribe_free(ptr, 0);
    }
    /**
     * @param {number} id
     * @returns {NetRequestGrpcUnsubscribe}
     */
    static create(id) {
        const ret = wasm.netrequestgrpcunsubscribe_create(id);
        return NetRequestGrpcUnsubscribe.__wrap(ret);
    }
}
if (Symbol.dispose) NetRequestGrpcUnsubscribe.prototype[Symbol.dispose] = NetRequestGrpcUnsubscribe.prototype.free;

export class NetRequestHttp {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(NetRequestHttp.prototype);
        obj.__wbg_ptr = ptr;
        NetRequestHttpFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        NetRequestHttpFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_netrequesthttp_free(ptr, 0);
    }
    /**
     * @param {string} method
     * @param {string} url
     * @param {Uint8Array | null | undefined} body
     * @param {NetHttpHeader[] | null | undefined} headers
     * @param {StreamEncoding} encoding
     * @param {NetHttpRetryConfig} retry
     * @param {number} streaming_id
     * @returns {NetRequestHttp}
     */
    static create(method, url, body, headers, encoding, retry, streaming_id) {
        const ptr0 = passStringToWasm0(method, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len0 = WASM_VECTOR_LEN;
        const ptr1 = passStringToWasm0(url, wasm.__wbindgen_export, wasm.__wbindgen_export2);
        const len1 = WASM_VECTOR_LEN;
        var ptr2 = isLikeNone(body) ? 0 : passArray8ToWasm0(body, wasm.__wbindgen_export);
        var len2 = WASM_VECTOR_LEN;
        var ptr3 = isLikeNone(headers) ? 0 : passArrayJsValueToWasm0(headers, wasm.__wbindgen_export);
        var len3 = WASM_VECTOR_LEN;
        _assertClass(retry, NetHttpRetryConfig);
        var ptr4 = retry.__destroy_into_raw();
        const ret = wasm.netrequesthttp_create(ptr0, len0, ptr1, len1, ptr2, len2, ptr3, len3, encoding, ptr4, streaming_id);
        return NetRequestHttp.__wrap(ret);
    }
}
if (Symbol.dispose) NetRequestHttp.prototype[Symbol.dispose] = NetRequestHttp.prototype.free;

export class NetRequestSocketSend {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(NetRequestSocketSend.prototype);
        obj.__wbg_ptr = ptr;
        NetRequestSocketSendFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        NetRequestSocketSendFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_netrequestsocketsend_free(ptr, 0);
    }
    /**
     * @param {Uint8Array} data
     * @returns {NetRequestSocketSend}
     */
    static create(data) {
        const ptr0 = passArray8ToWasm0(data, wasm.__wbindgen_export);
        const len0 = WASM_VECTOR_LEN;
        const ret = wasm.netrequestsocketsend_create(ptr0, len0);
        return NetRequestSocketSend.__wrap(ret);
    }
    /**
     * @param {any} v
     * @returns {NetRequestSocketSend}
     */
    static from_serde(v) {
        try {
            const ret = wasm.netrequestsocketsend_from_serde(addBorrowedObject(v));
            return NetRequestSocketSend.__wrap(ret);
        } finally {
            heap[stack_pointer++] = undefined;
        }
    }
}
if (Symbol.dispose) NetRequestSocketSend.prototype[Symbol.dispose] = NetRequestSocketSend.prototype.free;

export class NetRequestWasm {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(NetRequestWasm.prototype);
        obj.__wbg_ptr = ptr;
        NetRequestWasmFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        NetRequestWasmFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_netrequestwasm_free(ptr, 0);
    }
    /**
     * @param {number} transport_id
     * @param {number} id
     * @param {number} timeout
     * @param {number} kind
     * @param {NetRequestSocketSend | null} [socket_send]
     * @param {NetRequestGrpcUnary | null} [grpc_unary]
     * @param {NetRequestGrpcStream | null} [grpc_stream]
     * @param {NetRequestGrpcUnsubscribe | null} [grpc_unsubscribe]
     * @param {NetRequestHttp | null} [http]
     * @returns {NetRequestWasm}
     */
    static create(transport_id, id, timeout, kind, socket_send, grpc_unary, grpc_stream, grpc_unsubscribe, http) {
        let ptr0 = 0;
        if (!isLikeNone(socket_send)) {
            _assertClass(socket_send, NetRequestSocketSend);
            ptr0 = socket_send.__destroy_into_raw();
        }
        let ptr1 = 0;
        if (!isLikeNone(grpc_unary)) {
            _assertClass(grpc_unary, NetRequestGrpcUnary);
            ptr1 = grpc_unary.__destroy_into_raw();
        }
        let ptr2 = 0;
        if (!isLikeNone(grpc_stream)) {
            _assertClass(grpc_stream, NetRequestGrpcStream);
            ptr2 = grpc_stream.__destroy_into_raw();
        }
        let ptr3 = 0;
        if (!isLikeNone(grpc_unsubscribe)) {
            _assertClass(grpc_unsubscribe, NetRequestGrpcUnsubscribe);
            ptr3 = grpc_unsubscribe.__destroy_into_raw();
        }
        let ptr4 = 0;
        if (!isLikeNone(http)) {
            _assertClass(http, NetRequestHttp);
            ptr4 = http.__destroy_into_raw();
        }
        const ret = wasm.netrequestwasm_create(transport_id, id, timeout, kind, ptr0, ptr1, ptr2, ptr3, ptr4);
        return NetRequestWasm.__wrap(ret);
    }
    /**
     * @param {any} value
     * @returns {NetRequestWasm}
     */
    static fromserde(value) {
        try {
            const ret = wasm.netrequestwasm_fromserde(addBorrowedObject(value));
            return NetRequestWasm.__wrap(ret);
        } finally {
            heap[stack_pointer++] = undefined;
        }
    }
}
if (Symbol.dispose) NetRequestWasm.prototype[Symbol.dispose] = NetRequestWasm.prototype.free;

export class NetResponseGrpcSubscribe {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(NetResponseGrpcSubscribe.prototype);
        obj.__wbg_ptr = ptr;
        NetResponseGrpcSubscribeFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        NetResponseGrpcSubscribeFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_netresponsegrpcsubscribe_free(ptr, 0);
    }
    /**
     * Getter for `id`
     * @returns {number}
     */
    get id() {
        const ret = wasm.netresponsegrpcsubscribe_id(this.__wbg_ptr);
        return ret;
    }
    /**
     * @returns {string}
     */
    get message() {
        let deferred1_0;
        let deferred1_1;
        try {
            const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
            wasm.netresponsegrpcsubscribe_message(retptr, this.__wbg_ptr);
            var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
            var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
            deferred1_0 = r0;
            deferred1_1 = r1;
            return getStringFromWasm0(r0, r1);
        } finally {
            wasm.__wbindgen_add_to_stack_pointer(16);
            wasm.__wbindgen_export4(deferred1_0, deferred1_1, 1);
        }
    }
    /**
     * @returns {number}
     */
    get status() {
        const ret = wasm.netresponsegrpcsubscribe_status(this.__wbg_ptr);
        return ret;
    }
}
if (Symbol.dispose) NetResponseGrpcSubscribe.prototype[Symbol.dispose] = NetResponseGrpcSubscribe.prototype.free;

export class NetResponseGrpcUnary {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(NetResponseGrpcUnary.prototype);
        obj.__wbg_ptr = ptr;
        NetResponseGrpcUnaryFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        NetResponseGrpcUnaryFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_netresponsegrpcunary_free(ptr, 0);
    }
    /**
     * Getter for `data`
     * @returns {Uint8Array}
     */
    get data() {
        try {
            const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
            wasm.netresponsegrpcunary_data(retptr, this.__wbg_ptr);
            var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
            var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
            var v1 = getArrayU8FromWasm0(r0, r1).slice();
            wasm.__wbindgen_export4(r0, r1 * 1, 1);
            return v1;
        } finally {
            wasm.__wbindgen_add_to_stack_pointer(16);
        }
    }
    /**
     * @returns {string}
     */
    get message() {
        let deferred1_0;
        let deferred1_1;
        try {
            const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
            wasm.netresponsegrpcunary_message(retptr, this.__wbg_ptr);
            var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
            var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
            deferred1_0 = r0;
            deferred1_1 = r1;
            return getStringFromWasm0(r0, r1);
        } finally {
            wasm.__wbindgen_add_to_stack_pointer(16);
            wasm.__wbindgen_export4(deferred1_0, deferred1_1, 1);
        }
    }
    /**
     * @returns {number}
     */
    get status() {
        const ret = wasm.netresponsegrpcunary_status(this.__wbg_ptr);
        return ret;
    }
}
if (Symbol.dispose) NetResponseGrpcUnary.prototype[Symbol.dispose] = NetResponseGrpcUnary.prototype.free;

export class NetResponseGrpcUnsubscribe {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(NetResponseGrpcUnsubscribe.prototype);
        obj.__wbg_ptr = ptr;
        NetResponseGrpcUnsubscribeFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        NetResponseGrpcUnsubscribeFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_netresponsegrpcunsubscribe_free(ptr, 0);
    }
    /**
     * Getter for `id`
     * @returns {number}
     */
    get id() {
        const ret = wasm.netresponsegrpcunsubscribe_id(this.__wbg_ptr);
        return ret;
    }
}
if (Symbol.dispose) NetResponseGrpcUnsubscribe.prototype[Symbol.dispose] = NetResponseGrpcUnsubscribe.prototype.free;

export class NetResponseHttp {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(NetResponseHttp.prototype);
        obj.__wbg_ptr = ptr;
        NetResponseHttpFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        NetResponseHttpFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_netresponsehttp_free(ptr, 0);
    }
    /**
     * Getter for `body`
     * @returns {Uint8Array}
     */
    get body() {
        try {
            const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
            wasm.netresponsehttp_body(retptr, this.__wbg_ptr);
            var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
            var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
            var v1 = getArrayU8FromWasm0(r0, r1).slice();
            wasm.__wbindgen_export4(r0, r1 * 1, 1);
            return v1;
        } finally {
            wasm.__wbindgen_add_to_stack_pointer(16);
        }
    }
    /**
     * Getter for `headers`
     * @returns {NetHttpHeader[]}
     */
    get headers() {
        try {
            const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
            wasm.netresponsehttp_headers(retptr, this.__wbg_ptr);
            var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
            var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
            var v1 = getArrayJsValueFromWasm0(r0, r1).slice();
            wasm.__wbindgen_export4(r0, r1 * 4, 4);
            return v1;
        } finally {
            wasm.__wbindgen_add_to_stack_pointer(16);
        }
    }
    /**
     * Getter for `status_code`
     * @returns {number}
     */
    get status_code() {
        const ret = wasm.netresponsehttp_status_code(this.__wbg_ptr);
        return ret;
    }
    /**
     * Getter for `body`
     * @returns {number | undefined}
     */
    get stream_id() {
        const ret = wasm.netresponsehttp_stream_id(this.__wbg_ptr);
        return ret === 0x100000001 ? undefined : ret;
    }
}
if (Symbol.dispose) NetResponseHttp.prototype[Symbol.dispose] = NetResponseHttp.prototype.free;

export class NetResponseSocketStatus {
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        NetResponseSocketStatusFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_netresponsesocketstatus_free(ptr, 0);
    }
    /**
     * @returns {number}
     */
    get code() {
        const ret = wasm.netresponsesocketstatus_code(this.__wbg_ptr);
        return ret;
    }
    /**
     * @returns {string}
     */
    get message() {
        let deferred1_0;
        let deferred1_1;
        try {
            const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
            wasm.netresponsesocketstatus_message(retptr, this.__wbg_ptr);
            var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
            var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
            deferred1_0 = r0;
            deferred1_1 = r1;
            return getStringFromWasm0(r0, r1);
        } finally {
            wasm.__wbindgen_add_to_stack_pointer(16);
            wasm.__wbindgen_export4(deferred1_0, deferred1_1, 1);
        }
    }
}
if (Symbol.dispose) NetResponseSocketStatus.prototype[Symbol.dispose] = NetResponseSocketStatus.prototype.free;

export class NetResponseStreamData {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(NetResponseStreamData.prototype);
        obj.__wbg_ptr = ptr;
        NetResponseStreamDataFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        NetResponseStreamDataFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_netresponsestreamdata_free(ptr, 0);
    }
    /**
     * @returns {Uint8Array}
     */
    get data() {
        try {
            const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
            wasm.netresponsestreamdata_data(retptr, this.__wbg_ptr);
            var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
            var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
            var v1 = getArrayU8FromWasm0(r0, r1).slice();
            wasm.__wbindgen_export4(r0, r1 * 1, 1);
            return v1;
        } finally {
            wasm.__wbindgen_add_to_stack_pointer(16);
        }
    }
    /**
     * @returns {number | undefined}
     */
    get id() {
        const ret = wasm.netresponsestreamdata_id(this.__wbg_ptr);
        return ret === 0x100000001 ? undefined : ret;
    }
}
if (Symbol.dispose) NetResponseStreamData.prototype[Symbol.dispose] = NetResponseStreamData.prototype.free;

export class NetResponseStreamError {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(NetResponseStreamError.prototype);
        obj.__wbg_ptr = ptr;
        NetResponseStreamErrorFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        NetResponseStreamErrorFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_netresponsestreamerror_free(ptr, 0);
    }
    /**
     * @returns {number}
     */
    get code() {
        const ret = wasm.netresponsestreamerror_code(this.__wbg_ptr);
        return ret;
    }
    /**
     * Getter for `status`
     * @returns {NetResultStatus}
     */
    get error() {
        const ret = wasm.netresponsestreamerror_error(this.__wbg_ptr);
        return ret;
    }
    /**
     * Getter for `id`
     * @returns {number | undefined}
     */
    get id() {
        const ret = wasm.netresponsestreamerror_id(this.__wbg_ptr);
        return ret === 0x100000001 ? undefined : ret;
    }
    /**
     * @returns {string}
     */
    get message() {
        let deferred1_0;
        let deferred1_1;
        try {
            const retptr = wasm.__wbindgen_add_to_stack_pointer(-16);
            wasm.netresponsestreamerror_message(retptr, this.__wbg_ptr);
            var r0 = getDataViewMemory0().getInt32(retptr + 4 * 0, true);
            var r1 = getDataViewMemory0().getInt32(retptr + 4 * 1, true);
            deferred1_0 = r0;
            deferred1_1 = r1;
            return getStringFromWasm0(r0, r1);
        } finally {
            wasm.__wbindgen_add_to_stack_pointer(16);
            wasm.__wbindgen_export4(deferred1_0, deferred1_1, 1);
        }
    }
}
if (Symbol.dispose) NetResponseStreamError.prototype[Symbol.dispose] = NetResponseStreamError.prototype.free;

export class NetResponseWasm {
    static __wrap(ptr) {
        ptr = ptr >>> 0;
        const obj = Object.create(NetResponseWasm.prototype);
        obj.__wbg_ptr = ptr;
        NetResponseWasmFinalization.register(obj, obj.__wbg_ptr, obj);
        return obj;
    }
    __destroy_into_raw() {
        const ptr = this.__wbg_ptr;
        this.__wbg_ptr = 0;
        NetResponseWasmFinalization.unregister(this);
        return ptr;
    }
    free() {
        const ptr = this.__destroy_into_raw();
        wasm.__wbg_netresponsewasm_free(ptr, 0);
    }
    /**
     * @returns {NetResponseGrpcSubscribe | undefined}
     */
    get grpc_stream() {
        const ret = wasm.netresponsewasm_grpc_stream(this.__wbg_ptr);
        return ret === 0 ? undefined : NetResponseGrpcSubscribe.__wrap(ret);
    }
    /**
     * @returns {NetResponseGrpcUnary | undefined}
     */
    get grpc_unary() {
        const ret = wasm.netresponsewasm_grpc_unary(this.__wbg_ptr);
        return ret === 0 ? undefined : NetResponseGrpcUnary.__wrap(ret);
    }
    /**
     * @returns {NetResponseGrpcUnsubscribe | undefined}
     */
    get grpc_unsubscribe() {
        const ret = wasm.netresponsewasm_grpc_unsubscribe(this.__wbg_ptr);
        return ret === 0 ? undefined : NetResponseGrpcUnsubscribe.__wrap(ret);
    }
    /**
     * @returns {NetResponseHttp | undefined}
     */
    get http() {
        const ret = wasm.netresponsewasm_http(this.__wbg_ptr);
        return ret === 0 ? undefined : NetResponseHttp.__wrap(ret);
    }
    /**
     * @returns {number}
     */
    get kind() {
        const ret = wasm.netresponsewasm_kind(this.__wbg_ptr);
        return ret;
    }
    /**
     * @returns {number}
     */
    get request_id() {
        const ret = wasm.netresponsewasm_request_id(this.__wbg_ptr);
        return ret >>> 0;
    }
    /**
     * @returns {NetResultStatus | undefined}
     */
    get response_error() {
        const ret = wasm.netresponsewasm_response_error(this.__wbg_ptr);
        return ret === 0 ? undefined : ret;
    }
    /**
     * @returns {number | undefined}
     */
    get stream_close() {
        const ret = wasm.netresponsewasm_stream_close(this.__wbg_ptr);
        return ret === 0x100000001 ? undefined : ret;
    }
    /**
     * @returns {NetResponseStreamData | undefined}
     */
    get stream_data() {
        const ret = wasm.netresponsewasm_stream_data(this.__wbg_ptr);
        return ret === 0 ? undefined : NetResponseStreamData.__wrap(ret);
    }
    /**
     * @returns {NetResponseStreamError | undefined}
     */
    get stream_error() {
        const ret = wasm.netresponsewasm_stream_error(this.__wbg_ptr);
        return ret === 0 ? undefined : NetResponseStreamError.__wrap(ret);
    }
    /**
     * @returns {number}
     */
    get transport_id() {
        const ret = wasm.netresponsewasm_transport_id(this.__wbg_ptr);
        return ret >>> 0;
    }
}
if (Symbol.dispose) NetResponseWasm.prototype[Symbol.dispose] = NetResponseWasm.prototype.free;

/**
 * @enum {100 | 1 | 2 | 3 | 4 | 10 | 13 | 15 | 16 | 17 | 19 | 22 | 23 | 24 | 26 | 27 | 28}
 */
export const NetResultStatus = Object.freeze({
    OK: 100, "100": "OK",
    InvalidUrl: 1, "1": "InvalidUrl",
    TlsError: 2, "2": "TlsError",
    ConnectionError: 3, "3": "ConnectionError",
    TorNetError: 4, "4": "TorNetError",
    SocketError: 10, "10": "SocketError",
    Http2ConctionFailed: 13, "13": "Http2ConctionFailed",
    InvalidRequestParameters: 15, "15": "InvalidRequestParameters",
    InvalidConfigParameters: 16, "16": "InvalidConfigParameters",
    TransportNotFound: 17, "17": "TransportNotFound",
    BadHttpRequestHost: 19, "19": "BadHttpRequestHost",
    RequestTimeout: 22, "22": "RequestTimeout",
    InvalidTorConfig: 23, "23": "InvalidTorConfig",
    TorInitializationFailed: 24, "24": "TorInitializationFailed",
    TorClientNotInitialized: 26, "26": "TorClientNotInitialized",
    InternalError: 27, "27": "InternalError",
    InstanceDoesNotExist: 28, "28": "InstanceDoesNotExist",
});

/**
 * @enum {1 | 2 | 3 | 4 | 5}
 */
export const StreamEncoding = Object.freeze({
    Map: 1, "1": "Map",
    Raw: 2, "2": "Raw",
    ListOfMap: 3, "3": "ListOfMap",
    String: 4, "4": "String",
    Json: 5, "5": "Json",
});

export function start() {
    wasm.start();
}

function __wbg_get_imports() {
    const import0 = {
        __proto__: null,
        __wbg___wbindgen_boolean_get_bbbb1c18aa2f5e25: function(arg0) {
            const v = getObject(arg0);
            const ret = typeof(v) === 'boolean' ? v : undefined;
            return isLikeNone(ret) ? 0xFFFFFF : ret ? 1 : 0;
        },
        __wbg___wbindgen_debug_string_0bc8482c6e3508ae: function(arg0, arg1) {
            const ret = debugString(getObject(arg1));
            const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_export, wasm.__wbindgen_export2);
            const len1 = WASM_VECTOR_LEN;
            getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
            getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
        },
        __wbg___wbindgen_is_function_0095a73b8b156f76: function(arg0) {
            const ret = typeof(getObject(arg0)) === 'function';
            return ret;
        },
        __wbg___wbindgen_is_object_5ae8e5880f2c1fbd: function(arg0) {
            const val = getObject(arg0);
            const ret = typeof(val) === 'object' && val !== null;
            return ret;
        },
        __wbg___wbindgen_is_string_cd444516edc5b180: function(arg0) {
            const ret = typeof(getObject(arg0)) === 'string';
            return ret;
        },
        __wbg___wbindgen_is_undefined_9e4d92534c42d778: function(arg0) {
            const ret = getObject(arg0) === undefined;
            return ret;
        },
        __wbg___wbindgen_string_get_72fb696202c56729: function(arg0, arg1) {
            const obj = getObject(arg1);
            const ret = typeof(obj) === 'string' ? obj : undefined;
            var ptr1 = isLikeNone(ret) ? 0 : passStringToWasm0(ret, wasm.__wbindgen_export, wasm.__wbindgen_export2);
            var len1 = WASM_VECTOR_LEN;
            getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
            getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
        },
        __wbg___wbindgen_throw_be289d5034ed271b: function(arg0, arg1) {
            throw new Error(getStringFromWasm0(arg0, arg1));
        },
        __wbg__wbg_cb_unref_d9b87ff7982e3b21: function(arg0) {
            getObject(arg0)._wbg_cb_unref();
        },
        __wbg_abort_2f0584e03e8e3950: function(arg0) {
            getObject(arg0).abort();
        },
        __wbg_abort_d549b92d3c665de1: function(arg0, arg1) {
            getObject(arg0).abort(getObject(arg1));
        },
        __wbg_append_a992ccc37aa62dc4: function() { return handleError(function (arg0, arg1, arg2, arg3, arg4) {
            getObject(arg0).append(getStringFromWasm0(arg1, arg2), getStringFromWasm0(arg3, arg4));
        }, arguments); },
        __wbg_arrayBuffer_bb54076166006c39: function() { return handleError(function (arg0) {
            const ret = getObject(arg0).arrayBuffer();
            return addHeapObject(ret);
        }, arguments); },
        __wbg_body_3a0b4437dadea6bf: function(arg0) {
            const ret = getObject(arg0).body;
            return isLikeNone(ret) ? 0 : addHeapObject(ret);
        },
        __wbg_buffer_26d0910f3a5bc899: function(arg0) {
            const ret = getObject(arg0).buffer;
            return addHeapObject(ret);
        },
        __wbg_byobRequest_80e594e6da4e1af7: function(arg0) {
            const ret = getObject(arg0).byobRequest;
            return isLikeNone(ret) ? 0 : addHeapObject(ret);
        },
        __wbg_byteLength_3417f266f4bf562a: function(arg0) {
            const ret = getObject(arg0).byteLength;
            return ret;
        },
        __wbg_byteOffset_f88547ca47c86358: function(arg0) {
            const ret = getObject(arg0).byteOffset;
            return ret;
        },
        __wbg_call_389efe28435a9388: function() { return handleError(function (arg0, arg1) {
            const ret = getObject(arg0).call(getObject(arg1));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_call_4708e0c13bdc8e95: function() { return handleError(function (arg0, arg1, arg2) {
            const ret = getObject(arg0).call(getObject(arg1), getObject(arg2));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_cancel_2c0a0a251ff6b2b7: function(arg0) {
            const ret = getObject(arg0).cancel();
            return addHeapObject(ret);
        },
        __wbg_catch_c1f8c7623b458214: function(arg0, arg1) {
            const ret = getObject(arg0).catch(getObject(arg1));
            return addHeapObject(ret);
        },
        __wbg_clearTimeout_2e2c4939388cdfbb: function(arg0) {
            const ret = clearTimeout(takeObject(arg0));
            return addHeapObject(ret);
        },
        __wbg_clearTimeout_5a54f8841c30079a: function(arg0) {
            const ret = clearTimeout(takeObject(arg0));
            return addHeapObject(ret);
        },
        __wbg_close_06dfa0a815b9d71f: function() { return handleError(function (arg0) {
            getObject(arg0).close();
        }, arguments); },
        __wbg_close_1d08eaf57ed325c0: function() { return handleError(function (arg0) {
            getObject(arg0).close();
        }, arguments); },
        __wbg_close_a79afee31de55b36: function() { return handleError(function (arg0) {
            getObject(arg0).close();
        }, arguments); },
        __wbg_code_35e4ec59fbc7d427: function(arg0) {
            const ret = getObject(arg0).code;
            return ret;
        },
        __wbg_code_a552f1e91eda69b7: function(arg0) {
            const ret = getObject(arg0).code;
            return ret;
        },
        __wbg_data_5330da50312d0bc1: function(arg0) {
            const ret = getObject(arg0).data;
            return addHeapObject(ret);
        },
        __wbg_done_57b39ecd9addfe81: function(arg0) {
            const ret = getObject(arg0).done;
            return ret;
        },
        __wbg_enqueue_2c63f2044f257c3e: function() { return handleError(function (arg0, arg1) {
            getObject(arg0).enqueue(getObject(arg1));
        }, arguments); },
        __wbg_fetch_53eef7df7b439a49: function(arg0, arg1) {
            const ret = fetch(getObject(arg0), getObject(arg1));
            return addHeapObject(ret);
        },
        __wbg_fetch_c97461e1e8f610cd: function(arg0, arg1, arg2) {
            const ret = getObject(arg0).fetch(getObject(arg1), getObject(arg2));
            return addHeapObject(ret);
        },
        __wbg_fetch_e6e8e0a221783759: function(arg0, arg1) {
            const ret = getObject(arg0).fetch(getObject(arg1));
            return addHeapObject(ret);
        },
        __wbg_from_bddd64e7d5ff6941: function(arg0) {
            const ret = Array.from(getObject(arg0));
            return addHeapObject(ret);
        },
        __wbg_getReader_48e00749fe3f6089: function() { return handleError(function (arg0) {
            const ret = getObject(arg0).getReader();
            return addHeapObject(ret);
        }, arguments); },
        __wbg_get_9b94d73e6221f75c: function(arg0, arg1) {
            const ret = getObject(arg0)[arg1 >>> 0];
            return addHeapObject(ret);
        },
        __wbg_get_b3ed3ad4be2bc8ac: function() { return handleError(function (arg0, arg1) {
            const ret = Reflect.get(getObject(arg0), getObject(arg1));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_get_done_1ad1c16537f444c6: function(arg0) {
            const ret = getObject(arg0).done;
            return isLikeNone(ret) ? 0xFFFFFF : ret ? 1 : 0;
        },
        __wbg_get_value_6b77a1b7b90c9200: function(arg0) {
            const ret = getObject(arg0).value;
            return addHeapObject(ret);
        },
        __wbg_has_d4e53238966c12b6: function() { return handleError(function (arg0, arg1) {
            const ret = Reflect.has(getObject(arg0), getObject(arg1));
            return ret;
        }, arguments); },
        __wbg_headers_59a2938db9f80985: function(arg0) {
            const ret = getObject(arg0).headers;
            return addHeapObject(ret);
        },
        __wbg_headers_5a897f7fee9a0571: function(arg0) {
            const ret = getObject(arg0).headers;
            return addHeapObject(ret);
        },
        __wbg_instanceof_ArrayBuffer_c367199e2fa2aa04: function(arg0) {
            let result;
            try {
                result = getObject(arg0) instanceof ArrayBuffer;
            } catch (_) {
                result = false;
            }
            const ret = result;
            return ret;
        },
        __wbg_instanceof_Blob_ce92a9ddd729a84a: function(arg0) {
            let result;
            try {
                result = getObject(arg0) instanceof Blob;
            } catch (_) {
                result = false;
            }
            const ret = result;
            return ret;
        },
        __wbg_instanceof_ReadableStream_8ab3825017e203e9: function(arg0) {
            let result;
            try {
                result = getObject(arg0) instanceof ReadableStream;
            } catch (_) {
                result = false;
            }
            const ret = result;
            return ret;
        },
        __wbg_instanceof_Response_ee1d54d79ae41977: function(arg0) {
            let result;
            try {
                result = getObject(arg0) instanceof Response;
            } catch (_) {
                result = false;
            }
            const ret = result;
            return ret;
        },
        __wbg_instanceof_Window_ed49b2db8df90359: function(arg0) {
            let result;
            try {
                result = getObject(arg0) instanceof Window;
            } catch (_) {
                result = false;
            }
            const ret = result;
            return ret;
        },
        __wbg_iterator_6ff6560ca1568e55: function() {
            const ret = Symbol.iterator;
            return addHeapObject(ret);
        },
        __wbg_length_32ed9a279acd054c: function(arg0) {
            const ret = getObject(arg0).length;
            return ret;
        },
        __wbg_log_6b5ca2e6124b2808: function(arg0) {
            console.log(getObject(arg0));
        },
        __wbg_message_0b2b0298a231b0d4: function(arg0, arg1) {
            const ret = getObject(arg1).message;
            const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_export, wasm.__wbindgen_export2);
            const len1 = WASM_VECTOR_LEN;
            getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
            getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
        },
        __wbg_nethttpheader_new: function(arg0) {
            const ret = NetHttpHeader.__wrap(arg0);
            return addHeapObject(ret);
        },
        __wbg_nethttpheader_unwrap: function(arg0) {
            const ret = NetHttpHeader.__unwrap(getObject(arg0));
            return ret;
        },
        __wbg_netresponsewasm_new: function(arg0) {
            const ret = NetResponseWasm.__wrap(arg0);
            return addHeapObject(ret);
        },
        __wbg_new_057993d5b5e07835: function() { return handleError(function (arg0, arg1) {
            const ret = new WebSocket(getStringFromWasm0(arg0, arg1));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_new_361308b2356cecd0: function() {
            const ret = new Object();
            return addHeapObject(ret);
        },
        __wbg_new_3eb36ae241fe6f44: function() {
            const ret = new Array();
            return addHeapObject(ret);
        },
        __wbg_new_3ecd509f06237282: function() { return handleError(function (arg0) {
            const ret = new ReadableStreamDefaultReader(getObject(arg0));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_new_64284bd487f9d239: function() { return handleError(function () {
            const ret = new Headers();
            return addHeapObject(ret);
        }, arguments); },
        __wbg_new_72b49615380db768: function(arg0, arg1) {
            const ret = new Error(getStringFromWasm0(arg0, arg1));
            return addHeapObject(ret);
        },
        __wbg_new_b5d9e2fb389fef91: function(arg0, arg1) {
            try {
                var state0 = {a: arg0, b: arg1};
                var cb0 = (arg0, arg1) => {
                    const a = state0.a;
                    state0.a = 0;
                    try {
                        return __wasm_bindgen_func_elem_1389(a, state0.b, arg0, arg1);
                    } finally {
                        state0.a = a;
                    }
                };
                const ret = new Promise(cb0);
                return addHeapObject(ret);
            } finally {
                state0.a = state0.b = 0;
            }
        },
        __wbg_new_b949e7f56150a5d1: function() { return handleError(function () {
            const ret = new AbortController();
            return addHeapObject(ret);
        }, arguments); },
        __wbg_new_dd2b680c8bf6ae29: function(arg0) {
            const ret = new Uint8Array(getObject(arg0));
            return addHeapObject(ret);
        },
        __wbg_new_from_slice_a3d2629dc1826784: function(arg0, arg1) {
            const ret = new Uint8Array(getArrayU8FromWasm0(arg0, arg1));
            return addHeapObject(ret);
        },
        __wbg_new_no_args_1c7c842f08d00ebb: function(arg0, arg1) {
            const ret = new Function(getStringFromWasm0(arg0, arg1));
            return addHeapObject(ret);
        },
        __wbg_new_with_byte_offset_and_length_aa261d9c9da49eb1: function(arg0, arg1, arg2) {
            const ret = new Uint8Array(getObject(arg0), arg1 >>> 0, arg2 >>> 0);
            return addHeapObject(ret);
        },
        __wbg_new_with_str_and_init_a61cbc6bdef21614: function() { return handleError(function (arg0, arg1, arg2) {
            const ret = new Request(getStringFromWasm0(arg0, arg1), getObject(arg2));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_new_with_str_sequence_b67b3919b8b11238: function() { return handleError(function (arg0, arg1, arg2) {
            const ret = new WebSocket(getStringFromWasm0(arg0, arg1), getObject(arg2));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_next_3482f54c49e8af19: function() { return handleError(function (arg0) {
            const ret = getObject(arg0).next();
            return addHeapObject(ret);
        }, arguments); },
        __wbg_next_418f80d8f5303233: function(arg0) {
            const ret = getObject(arg0).next;
            return addHeapObject(ret);
        },
        __wbg_prototypesetcall_bdcdcc5842e4d77d: function(arg0, arg1, arg2) {
            Uint8Array.prototype.set.call(getArrayU8FromWasm0(arg0, arg1), getObject(arg2));
        },
        __wbg_push_8ffdcb2063340ba5: function(arg0, arg1) {
            const ret = getObject(arg0).push(getObject(arg1));
            return ret;
        },
        __wbg_queueMicrotask_0aa0a927f78f5d98: function(arg0) {
            const ret = getObject(arg0).queueMicrotask;
            return addHeapObject(ret);
        },
        __wbg_queueMicrotask_5bb536982f78a56f: function(arg0) {
            queueMicrotask(getObject(arg0));
        },
        __wbg_read_68fd377df67e19b0: function(arg0) {
            const ret = getObject(arg0).read();
            return addHeapObject(ret);
        },
        __wbg_readyState_1bb73ec7b8a54656: function(arg0) {
            const ret = getObject(arg0).readyState;
            return ret;
        },
        __wbg_reason_35fce8e55dd90f31: function(arg0, arg1) {
            const ret = getObject(arg1).reason;
            const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_export, wasm.__wbindgen_export2);
            const len1 = WASM_VECTOR_LEN;
            getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
            getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
        },
        __wbg_releaseLock_aa5846c2494b3032: function(arg0) {
            getObject(arg0).releaseLock();
        },
        __wbg_resolve_002c4b7d9d8f6b64: function(arg0) {
            const ret = Promise.resolve(getObject(arg0));
            return addHeapObject(ret);
        },
        __wbg_respond_bf6ab10399ca8722: function() { return handleError(function (arg0, arg1) {
            getObject(arg0).respond(arg1 >>> 0);
        }, arguments); },
        __wbg_send_542f95dea2df7994: function() { return handleError(function (arg0, arg1, arg2) {
            getObject(arg0).send(getArrayU8FromWasm0(arg1, arg2));
        }, arguments); },
        __wbg_send_bc0336a1b5ce4fb7: function() { return handleError(function (arg0, arg1, arg2) {
            getObject(arg0).send(getStringFromWasm0(arg1, arg2));
        }, arguments); },
        __wbg_setTimeout_929c97a7c0f23d36: function(arg0, arg1) {
            const ret = setTimeout(getObject(arg0), arg1);
            return addHeapObject(ret);
        },
        __wbg_setTimeout_db2dbaeefb6f39c7: function() { return handleError(function (arg0, arg1) {
            const ret = setTimeout(getObject(arg0), arg1);
            return addHeapObject(ret);
        }, arguments); },
        __wbg_set_binaryType_5bbf62e9f705dc1a: function(arg0, arg1) {
            getObject(arg0).binaryType = __wbindgen_enum_BinaryType[arg1];
        },
        __wbg_set_body_9a7e00afe3cfe244: function(arg0, arg1) {
            getObject(arg0).body = getObject(arg1);
        },
        __wbg_set_cache_315a3ed773a41543: function(arg0, arg1) {
            getObject(arg0).cache = __wbindgen_enum_RequestCache[arg1];
        },
        __wbg_set_cc56eefd2dd91957: function(arg0, arg1, arg2) {
            getObject(arg0).set(getArrayU8FromWasm0(arg1, arg2));
        },
        __wbg_set_credentials_c4a58d2e05ef24fb: function(arg0, arg1) {
            getObject(arg0).credentials = __wbindgen_enum_RequestCredentials[arg1];
        },
        __wbg_set_db769d02949a271d: function() { return handleError(function (arg0, arg1, arg2, arg3, arg4) {
            getObject(arg0).set(getStringFromWasm0(arg1, arg2), getStringFromWasm0(arg3, arg4));
        }, arguments); },
        __wbg_set_headers_cfc5f4b2c1f20549: function(arg0, arg1) {
            getObject(arg0).headers = getObject(arg1);
        },
        __wbg_set_integrity_aa1d5cf2e257cade: function(arg0, arg1, arg2) {
            getObject(arg0).integrity = getStringFromWasm0(arg1, arg2);
        },
        __wbg_set_method_c3e20375f5ae7fac: function(arg0, arg1, arg2) {
            getObject(arg0).method = getStringFromWasm0(arg1, arg2);
        },
        __wbg_set_mode_b13642c312648202: function(arg0, arg1) {
            getObject(arg0).mode = __wbindgen_enum_RequestMode[arg1];
        },
        __wbg_set_onclose_d382f3e2c2b850eb: function(arg0, arg1) {
            getObject(arg0).onclose = getObject(arg1);
        },
        __wbg_set_onerror_377f18bf4569bf85: function(arg0, arg1) {
            getObject(arg0).onerror = getObject(arg1);
        },
        __wbg_set_onmessage_2114aa5f4f53051e: function(arg0, arg1) {
            getObject(arg0).onmessage = getObject(arg1);
        },
        __wbg_set_onopen_b7b52d519d6c0f11: function(arg0, arg1) {
            getObject(arg0).onopen = getObject(arg1);
        },
        __wbg_set_redirect_a7956fa3f817cbbc: function(arg0, arg1) {
            getObject(arg0).redirect = __wbindgen_enum_RequestRedirect[arg1];
        },
        __wbg_set_referrer_aa8e6f0f198f18cd: function(arg0, arg1, arg2) {
            getObject(arg0).referrer = getStringFromWasm0(arg1, arg2);
        },
        __wbg_set_referrer_policy_544ba074b97231a6: function(arg0, arg1) {
            getObject(arg0).referrerPolicy = __wbindgen_enum_ReferrerPolicy[arg1];
        },
        __wbg_set_signal_f2d3f8599248896d: function(arg0, arg1) {
            getObject(arg0).signal = getObject(arg1);
        },
        __wbg_signal_d1285ecab4ebc5ad: function(arg0) {
            const ret = getObject(arg0).signal;
            return addHeapObject(ret);
        },
        __wbg_static_accessor_GLOBAL_12837167ad935116: function() {
            const ret = typeof global === 'undefined' ? null : global;
            return isLikeNone(ret) ? 0 : addHeapObject(ret);
        },
        __wbg_static_accessor_GLOBAL_THIS_e628e89ab3b1c95f: function() {
            const ret = typeof globalThis === 'undefined' ? null : globalThis;
            return isLikeNone(ret) ? 0 : addHeapObject(ret);
        },
        __wbg_static_accessor_SELF_a621d3dfbb60d0ce: function() {
            const ret = typeof self === 'undefined' ? null : self;
            return isLikeNone(ret) ? 0 : addHeapObject(ret);
        },
        __wbg_static_accessor_WINDOW_f8727f0cf888e0bd: function() {
            const ret = typeof window === 'undefined' ? null : window;
            return isLikeNone(ret) ? 0 : addHeapObject(ret);
        },
        __wbg_status_89d7e803db911ee7: function(arg0) {
            const ret = getObject(arg0).status;
            return ret;
        },
        __wbg_stringify_8d1cc6ff383e8bae: function() { return handleError(function (arg0) {
            const ret = JSON.stringify(getObject(arg0));
            return addHeapObject(ret);
        }, arguments); },
        __wbg_then_0d9fe2c7b1857d32: function(arg0, arg1, arg2) {
            const ret = getObject(arg0).then(getObject(arg1), getObject(arg2));
            return addHeapObject(ret);
        },
        __wbg_then_b9e7b3b5f1a9e1b5: function(arg0, arg1) {
            const ret = getObject(arg0).then(getObject(arg1));
            return addHeapObject(ret);
        },
        __wbg_toString_964ff7fe6eca8362: function(arg0) {
            const ret = getObject(arg0).toString();
            return addHeapObject(ret);
        },
        __wbg_url_cb4d34db86c24df9: function(arg0, arg1) {
            const ret = getObject(arg1).url;
            const ptr1 = passStringToWasm0(ret, wasm.__wbindgen_export, wasm.__wbindgen_export2);
            const len1 = WASM_VECTOR_LEN;
            getDataViewMemory0().setInt32(arg0 + 4 * 1, len1, true);
            getDataViewMemory0().setInt32(arg0 + 4 * 0, ptr1, true);
        },
        __wbg_value_0546255b415e96c1: function(arg0) {
            const ret = getObject(arg0).value;
            return addHeapObject(ret);
        },
        __wbg_view_6c32e7184b8606ad: function(arg0) {
            const ret = getObject(arg0).view;
            return isLikeNone(ret) ? 0 : addHeapObject(ret);
        },
        __wbg_wasClean_a9c77a7100d8534f: function(arg0) {
            const ret = getObject(arg0).wasClean;
            return ret;
        },
        __wbindgen_cast_0000000000000001: function(arg0, arg1) {
            // Cast intrinsic for `Closure(Closure { dtor_idx: 55, function: Function { arguments: [NamedExternref("CloseEvent")], shim_idx: 58, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
            const ret = makeMutClosure(arg0, arg1, wasm.__wasm_bindgen_func_elem_1193, __wasm_bindgen_func_elem_1192);
            return addHeapObject(ret);
        },
        __wbindgen_cast_0000000000000002: function(arg0, arg1) {
            // Cast intrinsic for `Closure(Closure { dtor_idx: 55, function: Function { arguments: [], shim_idx: 56, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
            const ret = makeMutClosure(arg0, arg1, wasm.__wasm_bindgen_func_elem_1193, __wasm_bindgen_func_elem_1195);
            return addHeapObject(ret);
        },
        __wbindgen_cast_0000000000000003: function(arg0, arg1) {
            // Cast intrinsic for `Closure(Closure { dtor_idx: 60, function: Function { arguments: [Externref], shim_idx: 58, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
            const ret = makeMutClosure(arg0, arg1, wasm.__wasm_bindgen_func_elem_1198, __wasm_bindgen_func_elem_1192);
            return addHeapObject(ret);
        },
        __wbindgen_cast_0000000000000004: function(arg0, arg1) {
            // Cast intrinsic for `Closure(Closure { dtor_idx: 60, function: Function { arguments: [NamedExternref("MessageEvent")], shim_idx: 58, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
            const ret = makeMutClosure(arg0, arg1, wasm.__wasm_bindgen_func_elem_1198, __wasm_bindgen_func_elem_1192);
            return addHeapObject(ret);
        },
        __wbindgen_cast_0000000000000005: function(arg0, arg1) {
            // Cast intrinsic for `Closure(Closure { dtor_idx: 60, function: Function { arguments: [], shim_idx: 56, ret: Unit, inner_ret: Some(Unit) }, mutable: true }) -> Externref`.
            const ret = makeMutClosure(arg0, arg1, wasm.__wasm_bindgen_func_elem_1198, __wasm_bindgen_func_elem_1195);
            return addHeapObject(ret);
        },
        __wbindgen_cast_0000000000000006: function(arg0) {
            // Cast intrinsic for `F64 -> Externref`.
            const ret = arg0;
            return addHeapObject(ret);
        },
        __wbindgen_cast_0000000000000007: function(arg0, arg1) {
            // Cast intrinsic for `Ref(String) -> Externref`.
            const ret = getStringFromWasm0(arg0, arg1);
            return addHeapObject(ret);
        },
        __wbindgen_object_clone_ref: function(arg0) {
            const ret = getObject(arg0);
            return addHeapObject(ret);
        },
        __wbindgen_object_drop_ref: function(arg0) {
            takeObject(arg0);
        },
    };
    return {
        __proto__: null,
        "./net_sdk_bg.js": import0,
    };
}

function __wasm_bindgen_func_elem_1195(arg0, arg1) {
    wasm.__wasm_bindgen_func_elem_1195(arg0, arg1);
}

function __wasm_bindgen_func_elem_1192(arg0, arg1, arg2) {
    wasm.__wasm_bindgen_func_elem_1192(arg0, arg1, addHeapObject(arg2));
}

function __wasm_bindgen_func_elem_1389(arg0, arg1, arg2, arg3) {
    wasm.__wasm_bindgen_func_elem_1389(arg0, arg1, addHeapObject(arg2), addHeapObject(arg3));
}


const __wbindgen_enum_BinaryType = ["blob", "arraybuffer"];


const __wbindgen_enum_ReadableStreamType = ["bytes"];


const __wbindgen_enum_ReferrerPolicy = ["", "no-referrer", "no-referrer-when-downgrade", "origin", "origin-when-cross-origin", "unsafe-url", "same-origin", "strict-origin", "strict-origin-when-cross-origin"];


const __wbindgen_enum_RequestCache = ["default", "no-store", "reload", "no-cache", "force-cache", "only-if-cached"];


const __wbindgen_enum_RequestCredentials = ["omit", "same-origin", "include"];


const __wbindgen_enum_RequestMode = ["same-origin", "no-cors", "cors", "navigate"];


const __wbindgen_enum_RequestRedirect = ["follow", "error", "manual"];
const DartTransporterFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_darttransporter_free(ptr >>> 0, 1));
const IntoUnderlyingByteSourceFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_intounderlyingbytesource_free(ptr >>> 0, 1));
const IntoUnderlyingSinkFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_intounderlyingsink_free(ptr >>> 0, 1));
const IntoUnderlyingSourceFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_intounderlyingsource_free(ptr >>> 0, 1));
const NetConfigHttpWasmFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_netconfighttpwasm_free(ptr >>> 0, 1));
const NetConfigRequestWasmFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_netconfigrequestwasm_free(ptr >>> 0, 1));
const NetHttpHeaderFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_nethttpheader_free(ptr >>> 0, 1));
const NetHttpRetryConfigFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_nethttpretryconfig_free(ptr >>> 0, 1));
const NetRequestGrpcStreamFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_netrequestgrpcstream_free(ptr >>> 0, 1));
const NetRequestGrpcUnaryFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_netrequestgrpcunary_free(ptr >>> 0, 1));
const NetRequestGrpcUnsubscribeFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_netrequestgrpcunsubscribe_free(ptr >>> 0, 1));
const NetRequestHttpFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_netrequesthttp_free(ptr >>> 0, 1));
const NetRequestSocketSendFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_netrequestsocketsend_free(ptr >>> 0, 1));
const NetRequestWasmFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_netrequestwasm_free(ptr >>> 0, 1));
const NetResponseGrpcSubscribeFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_netresponsegrpcsubscribe_free(ptr >>> 0, 1));
const NetResponseGrpcUnaryFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_netresponsegrpcunary_free(ptr >>> 0, 1));
const NetResponseGrpcUnsubscribeFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_netresponsegrpcunsubscribe_free(ptr >>> 0, 1));
const NetResponseHttpFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_netresponsehttp_free(ptr >>> 0, 1));
const NetResponseSocketStatusFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_netresponsesocketstatus_free(ptr >>> 0, 1));
const NetResponseStreamDataFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_netresponsestreamdata_free(ptr >>> 0, 1));
const NetResponseStreamErrorFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_netresponsestreamerror_free(ptr >>> 0, 1));
const NetResponseWasmFinalization = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(ptr => wasm.__wbg_netresponsewasm_free(ptr >>> 0, 1));

function addHeapObject(obj) {
    if (heap_next === heap.length) heap.push(heap.length + 1);
    const idx = heap_next;
    heap_next = heap[idx];

    heap[idx] = obj;
    return idx;
}

function _assertClass(instance, klass) {
    if (!(instance instanceof klass)) {
        throw new Error(`expected instance of ${klass.name}`);
    }
}

function addBorrowedObject(obj) {
    if (stack_pointer == 1) throw new Error('out of js stack');
    heap[--stack_pointer] = obj;
    return stack_pointer;
}

const CLOSURE_DTORS = (typeof FinalizationRegistry === 'undefined')
    ? { register: () => {}, unregister: () => {} }
    : new FinalizationRegistry(state => state.dtor(state.a, state.b));

function debugString(val) {
    // primitive types
    const type = typeof val;
    if (type == 'number' || type == 'boolean' || val == null) {
        return  `${val}`;
    }
    if (type == 'string') {
        return `"${val}"`;
    }
    if (type == 'symbol') {
        const description = val.description;
        if (description == null) {
            return 'Symbol';
        } else {
            return `Symbol(${description})`;
        }
    }
    if (type == 'function') {
        const name = val.name;
        if (typeof name == 'string' && name.length > 0) {
            return `Function(${name})`;
        } else {
            return 'Function';
        }
    }
    // objects
    if (Array.isArray(val)) {
        const length = val.length;
        let debug = '[';
        if (length > 0) {
            debug += debugString(val[0]);
        }
        for(let i = 1; i < length; i++) {
            debug += ', ' + debugString(val[i]);
        }
        debug += ']';
        return debug;
    }
    // Test for built-in
    const builtInMatches = /\[object ([^\]]+)\]/.exec(toString.call(val));
    let className;
    if (builtInMatches && builtInMatches.length > 1) {
        className = builtInMatches[1];
    } else {
        // Failed to match the standard '[object ClassName]'
        return toString.call(val);
    }
    if (className == 'Object') {
        // we're a user defined class or Object
        // JSON.stringify avoids problems with cycles, and is generally much
        // easier than looping through ownProperties of `val`.
        try {
            return 'Object(' + JSON.stringify(val) + ')';
        } catch (_) {
            return 'Object';
        }
    }
    // errors
    if (val instanceof Error) {
        return `${val.name}: ${val.message}\n${val.stack}`;
    }
    // TODO we could test for more things here, like `Set`s and `Map`s.
    return className;
}

function dropObject(idx) {
    if (idx < 132) return;
    heap[idx] = heap_next;
    heap_next = idx;
}

function getArrayJsValueFromWasm0(ptr, len) {
    ptr = ptr >>> 0;
    const mem = getDataViewMemory0();
    const result = [];
    for (let i = ptr; i < ptr + 4 * len; i += 4) {
        result.push(takeObject(mem.getUint32(i, true)));
    }
    return result;
}

function getArrayU8FromWasm0(ptr, len) {
    ptr = ptr >>> 0;
    return getUint8ArrayMemory0().subarray(ptr / 1, ptr / 1 + len);
}

let cachedDataViewMemory0 = null;
function getDataViewMemory0() {
    if (cachedDataViewMemory0 === null || cachedDataViewMemory0.buffer.detached === true || (cachedDataViewMemory0.buffer.detached === undefined && cachedDataViewMemory0.buffer !== wasm.memory.buffer)) {
        cachedDataViewMemory0 = new DataView(wasm.memory.buffer);
    }
    return cachedDataViewMemory0;
}

function getStringFromWasm0(ptr, len) {
    ptr = ptr >>> 0;
    return decodeText(ptr, len);
}

let cachedUint16ArrayMemory0 = null;
function getUint16ArrayMemory0() {
    if (cachedUint16ArrayMemory0 === null || cachedUint16ArrayMemory0.byteLength === 0) {
        cachedUint16ArrayMemory0 = new Uint16Array(wasm.memory.buffer);
    }
    return cachedUint16ArrayMemory0;
}

let cachedUint8ArrayMemory0 = null;
function getUint8ArrayMemory0() {
    if (cachedUint8ArrayMemory0 === null || cachedUint8ArrayMemory0.byteLength === 0) {
        cachedUint8ArrayMemory0 = new Uint8Array(wasm.memory.buffer);
    }
    return cachedUint8ArrayMemory0;
}

function getObject(idx) { return heap[idx]; }

function handleError(f, args) {
    try {
        return f.apply(this, args);
    } catch (e) {
        wasm.__wbindgen_export3(addHeapObject(e));
    }
}

let heap = new Array(128).fill(undefined);
heap.push(undefined, null, true, false);

let heap_next = heap.length;

function isLikeNone(x) {
    return x === undefined || x === null;
}

function makeMutClosure(arg0, arg1, dtor, f) {
    const state = { a: arg0, b: arg1, cnt: 1, dtor };
    const real = (...args) => {

        // First up with a closure we increment the internal reference
        // count. This ensures that the Rust closure environment won't
        // be deallocated while we're invoking it.
        state.cnt++;
        const a = state.a;
        state.a = 0;
        try {
            return f(a, state.b, ...args);
        } finally {
            state.a = a;
            real._wbg_cb_unref();
        }
    };
    real._wbg_cb_unref = () => {
        if (--state.cnt === 0) {
            state.dtor(state.a, state.b);
            state.a = 0;
            CLOSURE_DTORS.unregister(state);
        }
    };
    CLOSURE_DTORS.register(real, state, state);
    return real;
}

function passArray16ToWasm0(arg, malloc) {
    const ptr = malloc(arg.length * 2, 2) >>> 0;
    getUint16ArrayMemory0().set(arg, ptr / 2);
    WASM_VECTOR_LEN = arg.length;
    return ptr;
}

function passArray8ToWasm0(arg, malloc) {
    const ptr = malloc(arg.length * 1, 1) >>> 0;
    getUint8ArrayMemory0().set(arg, ptr / 1);
    WASM_VECTOR_LEN = arg.length;
    return ptr;
}

function passArrayJsValueToWasm0(array, malloc) {
    const ptr = malloc(array.length * 4, 4) >>> 0;
    const mem = getDataViewMemory0();
    for (let i = 0; i < array.length; i++) {
        mem.setUint32(ptr + 4 * i, addHeapObject(array[i]), true);
    }
    WASM_VECTOR_LEN = array.length;
    return ptr;
}

function passStringToWasm0(arg, malloc, realloc) {
    if (realloc === undefined) {
        const buf = cachedTextEncoder.encode(arg);
        const ptr = malloc(buf.length, 1) >>> 0;
        getUint8ArrayMemory0().subarray(ptr, ptr + buf.length).set(buf);
        WASM_VECTOR_LEN = buf.length;
        return ptr;
    }

    let len = arg.length;
    let ptr = malloc(len, 1) >>> 0;

    const mem = getUint8ArrayMemory0();

    let offset = 0;

    for (; offset < len; offset++) {
        const code = arg.charCodeAt(offset);
        if (code > 0x7F) break;
        mem[ptr + offset] = code;
    }
    if (offset !== len) {
        if (offset !== 0) {
            arg = arg.slice(offset);
        }
        ptr = realloc(ptr, len, len = offset + arg.length * 3, 1) >>> 0;
        const view = getUint8ArrayMemory0().subarray(ptr + offset, ptr + len);
        const ret = cachedTextEncoder.encodeInto(arg, view);

        offset += ret.written;
        ptr = realloc(ptr, len, offset, 1) >>> 0;
    }

    WASM_VECTOR_LEN = offset;
    return ptr;
}

let stack_pointer = 128;

function takeObject(idx) {
    const ret = getObject(idx);
    dropObject(idx);
    return ret;
}

let cachedTextDecoder = new TextDecoder('utf-8', { ignoreBOM: true, fatal: true });
cachedTextDecoder.decode();
const MAX_SAFARI_DECODE_BYTES = 2146435072;
let numBytesDecoded = 0;
function decodeText(ptr, len) {
    numBytesDecoded += len;
    if (numBytesDecoded >= MAX_SAFARI_DECODE_BYTES) {
        cachedTextDecoder = new TextDecoder('utf-8', { ignoreBOM: true, fatal: true });
        cachedTextDecoder.decode();
        numBytesDecoded = len;
    }
    return cachedTextDecoder.decode(getUint8ArrayMemory0().subarray(ptr, ptr + len));
}

const cachedTextEncoder = new TextEncoder();

if (!('encodeInto' in cachedTextEncoder)) {
    cachedTextEncoder.encodeInto = function (arg, view) {
        const buf = cachedTextEncoder.encode(arg);
        view.set(buf);
        return {
            read: arg.length,
            written: buf.length
        };
    };
}

let WASM_VECTOR_LEN = 0;

let wasmModule, wasm;
function __wbg_finalize_init(instance, module) {
    wasm = instance.exports;
    wasmModule = module;
    cachedDataViewMemory0 = null;
    cachedUint16ArrayMemory0 = null;
    cachedUint8ArrayMemory0 = null;
    wasm.__wbindgen_start();
    return wasm;
}

async function __wbg_load(module, imports) {
    if (typeof Response === 'function' && module instanceof Response) {
        if (typeof WebAssembly.instantiateStreaming === 'function') {
            try {
                return await WebAssembly.instantiateStreaming(module, imports);
            } catch (e) {
                const validResponse = module.ok && expectedResponseType(module.type);

                if (validResponse && module.headers.get('Content-Type') !== 'application/wasm') {
                    console.warn("`WebAssembly.instantiateStreaming` failed because your server does not serve Wasm with `application/wasm` MIME type. Falling back to `WebAssembly.instantiate` which is slower. Original error:\n", e);

                } else { throw e; }
            }
        }

        const bytes = await module.arrayBuffer();
        return await WebAssembly.instantiate(bytes, imports);
    } else {
        const instance = await WebAssembly.instantiate(module, imports);

        if (instance instanceof WebAssembly.Instance) {
            return { instance, module };
        } else {
            return instance;
        }
    }

    function expectedResponseType(type) {
        switch (type) {
            case 'basic': case 'cors': case 'default': return true;
        }
        return false;
    }
}

function initSync(module) {
    if (wasm !== undefined) return wasm;


    if (module !== undefined) {
        if (Object.getPrototypeOf(module) === Object.prototype) {
            ({module} = module)
        } else {
            console.warn('using deprecated parameters for `initSync()`; pass a single object instead')
        }
    }

    const imports = __wbg_get_imports();
    if (!(module instanceof WebAssembly.Module)) {
        module = new WebAssembly.Module(module);
    }
    const instance = new WebAssembly.Instance(module, imports);
    return __wbg_finalize_init(instance, module);
}

async function __wbg_init(module_or_path) {
    if (wasm !== undefined) return wasm;


    if (module_or_path !== undefined) {
        if (Object.getPrototypeOf(module_or_path) === Object.prototype) {
            ({module_or_path} = module_or_path)
        } else {
            console.warn('using deprecated parameters for the initialization function; pass a single object instead')
        }
    }

    if (module_or_path === undefined) {
        module_or_path = new URL('net_sdk_bg.wasm', import.meta.url);
    }
    const imports = __wbg_get_imports();

    if (typeof module_or_path === 'string' || (typeof Request === 'function' && module_or_path instanceof Request) || (typeof URL === 'function' && module_or_path instanceof URL)) {
        module_or_path = fetch(module_or_path);
    }

    const { instance, module } = await __wbg_load(await module_or_path, imports);

    return __wbg_finalize_init(instance, module);
}

export { initSync, __wbg_init as default };
