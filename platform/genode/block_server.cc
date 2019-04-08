
#include <session/session.h>
#include <block/request_stream.h>
#include <block_session/block_session.h>

#include <genode_packet.h>
#include <block_root.h>
namespace Cai {
    namespace Block {
        struct Block_session_component;
        struct Block_root;
    }
}

#include <factory.h>

extern Genode::Env *__genode_env;
static Factory _factory {*__genode_env};

extern "C" bool cai_block_server_writable(Cai::Block::Block_root *, void*);

Cai::Block::Block_session_component::Block_session_component(
        Genode::Region_map &rm,
        Genode::Dataspace_capability ds,
        Genode::Entrypoint &ep,
        Genode::Signal_context_capability sigh,
        Cai::Block::Block_root *server) :
    Request_stream(rm, ds, ep, sigh, server->_block_size(static_cast<void *>(server))),
    _ep(ep),
    _server(server)
{
    _ep.manage(*this);
}

Cai::Block::Block_session_component::~Block_session_component()
{
    _ep.dissolve(*this);
}

void Cai::Block::Block_session_component::info(::Block::sector_t *count, Genode::size_t *size, ::Block::Session::Operations *ops)
{
    *count = _server->_block_count(static_cast<void *>(_server));
    *size = _server->_block_size(static_cast<void *>(_server));
    *ops = ::Block::Session::Operations();
    ops->set_operation(::Block::Packet_descriptor::Opcode::READ);
    if(cai_block_server_writable(_server, _server->_writable)){
        ops->set_operation(::Block::Packet_descriptor::Opcode::WRITE);
    }
}

void Cai::Block::Block_session_component::sync()
{ }

Genode::Capability<::Block::Session::Tx> Cai::Block::Block_session_component::tx_cap()
{
    return Request_stream::tx_cap();
}

Cai::Block::Block_root::Block_root(Genode::Env &env,
                                   Genode::size_t ds_size,
                                   void (*callback)(),
                                   Genode::uint64_t (*block_count)(void *),
                                   Genode::uint64_t (*block_size)(void *),
                                   Genode::uint64_t (*maximal_transfer_size)(void *),
                                   void *writable) :
    _env(env),
    _sigh(env.ep(), *this, &Cai::Block::Block_root::handler),
    _ds(env.ram(), env.rm(), ds_size),
    _callback(callback),
    _block_count(block_count),
    _block_size(block_size),
    _maximal_transfer_size(maximal_transfer_size),
    _writable(writable),
    _session(env.rm(), _ds.cap(), env.ep(), _sigh, this)
{ }

void Cai::Block::Block_root::handler()
{
    _callback();
    _session.wakeup_client();
}

Genode::Capability<Genode::Session> Cai::Block::Block_root::cap()
{
    return _session.cap();
}

extern "C" {

    void cai_block_server_initialize(
            void **session,
            Genode::uint64_t size,
            void *callback,
            void *block_count,
            void *block_size,
            void *maximal_transfer_size,
            void *writable)
    {
        *session = _factory.create<Cai::Block::Block_root>(
                *__genode_env,
                static_cast<Genode::size_t>(size),
                reinterpret_cast<void (*)()>(callback),
                reinterpret_cast<Genode::uint64_t (*)(void *)>(block_count),
                reinterpret_cast<Genode::uint64_t (*)(void *)>(block_size),
                reinterpret_cast<Genode::uint64_t (*)(void *)>(maximal_transfer_size),
                writable);
    }

    void cai_block_server_finalize(void **session)
    {
        _factory.destroy<Cai::Block::Block_root>(*session);
        *session = nullptr;
    }

    static Cai::Block::Block_session_component &blk(void *session)
    {
        return static_cast<Cai::Block::Block_root *>(session)->_session;
    }

    Cai::Block::Request cai_block_server_head(void *session)
    {
        Cai::Block::Request request = Cai::Block::Request {Cai::Block::NONE, {}, 0, 0, Cai::Block::RAW};
        blk(session).with_requests([&] (::Block::Request req) {
                request = create_cai_block_request (req);
                request.status = Cai::Block::RAW;
                return Cai::Block::Block_session_component::Response::RETRY;
                });
        return request;
    }

    void cai_block_server_discard(void *session)
    {
        bool accepted = false;
        blk(session).with_requests([&] (::Block::Request) {
                if(accepted){
                return Cai::Block::Block_session_component::Response::RETRY;
                }else{
                accepted = true;
                return Cai::Block::Block_session_component::Response::ACCEPTED;
                }
                });
    }

    void cai_block_server_read(void *session, Cai::Block::Request request, void *buffer)
    {
        ::Block::Request req = create_genode_block_request(request);
        blk(session).with_content(req, [&] (void *ptr, Genode::size_t size){
                Genode::memcpy(ptr, buffer, size);
                });
    }

    void cai_block_server_write(void *session, Cai::Block::Request request, void *buffer)
    {
        ::Block::Request req = create_genode_block_request(request);
        blk(session).with_content(req, [&] (void *ptr, Genode::size_t size){
                Genode::memcpy(buffer, ptr, size);
                });
    }

    void cai_block_server_acknowledge(void *session, Cai::Block::Request &req)
    {
        bool acked = false;
        blk(session).try_acknowledge([&] (Cai::Block::Block_session_component::Ack &ack){
                if (acked) {
                req.status = Cai::Block::ACK;
                } else {
                ack.submit(create_genode_block_request(req));
                acked = true;
                }
                });
    }

}
