#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <chrono>
#include <cstdint>
using namespace godot;
extern "C" int m20_cpp_compute(const uint8_t*,size_t,uint8_t*,size_t) noexcept;
extern "C" int m20_rust_compute(const uint8_t*,size_t,uint8_t*,size_t);
class M20Math : public RefCounted {
 GDCLASS(M20Math,RefCounted)
 protected:
 static void _bind_methods(){ClassDB::bind_method(D_METHOD("compute","backend","input"),&M20Math::compute);}
 public:
 Dictionary compute(const String& backend,const PackedByteArray& input){
  using Clock=std::chrono::steady_clock;auto entry=Clock::now();Dictionary d;d["ok"]=false;
  if((backend!="cpp"&&backend!="rust")||input.size()<16){d["error"]="invalid backend/header";return d;}
  auto u=[&](int offset){uint32_t v=0;for(int i=0;i<4;i++)v|=uint32_t(input[offset+i])<<(8*i);return v;};
  uint32_t op=u(8),count=u(12);
  if(u(0)!=0x4b30324d||u(4)!=1||(op!=1&&op!=2)||count>100000){d["error"]="invalid schema";return d;}
  PackedByteArray output;output.resize(16+size_t(count)*(op==1?325:1)*8);
  auto start=Clock::now();int status=backend=="cpp"?m20_cpp_compute(input.ptr(),input.size(),output.ptrw(),output.size()):m20_rust_compute(input.ptr(),input.size(),output.ptrw(),output.size());auto stop=Clock::now();
  if(status){d["error"]=String("numerical kernel rejected input, status ")+String::num_int64(status);return d;}
  d["ok"]=true;d["output"]=output;
  d["compute_usec"]=std::chrono::duration<double,std::micro>(stop-start).count();
  d["bridge_usec"]=std::chrono::duration<double,std::micro>(Clock::now()-entry).count();return d;
 }
};
void initialize(ModuleInitializationLevel l){if(l==MODULE_INITIALIZATION_LEVEL_SCENE)GDREGISTER_CLASS(M20Math);}
void terminate(ModuleInitializationLevel){}
extern "C" GDExtensionBool GDE_EXPORT m20_library_init(GDExtensionInterfaceGetProcAddress p,GDExtensionClassLibraryPtr l,GDExtensionInitialization* i){
 GDExtensionBinding::InitObject init(p,l,i);init.register_initializer(initialize);init.register_terminator(terminate);init.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);return init.init();
}
