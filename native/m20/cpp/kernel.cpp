#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <vector>
#include <stdexcept>
namespace {
using Row=std::array<double,25>;
using Forecast=std::array<Row,13>;
using State=std::array<double,4>;
struct Reader {
 const uint8_t* p; size_t left;
 uint32_t u(){if(left<4)throw 1; uint32_t v=0;for(int i=0;i<4;i++)v|=uint32_t(p[i])<<(8*i);p+=4;left-=4;return v;}
 double d(){if(left<8)throw 1;uint64_t v=0;for(int i=0;i<8;i++)v|=uint64_t(p[i])<<(8*i);double x;std::memcpy(&x,&v,8);p+=8;left-=8;if(!std::isfinite(x))throw 2;return x;}
};
void write_double(uint8_t* p,double x){uint64_t v;std::memcpy(&v,&x,8);for(int i=0;i<8;i++)p[i]=uint8_t(v>>(8*i));}
void normalized(const double* a,int n){double sum=0;for(int i=0;i<n;i++){if(a[i]<0)throw 2;sum+=a[i];}if(std::abs(sum-1)>1e-9)throw 2;}
double prior(int h){return h<12?0.8/12.0:0.2;}
Forecast forecast(Reader& r,int price,int carry){
 std::array<std::array<double,13>,2> alpha{},weights{};
 for(int c=0;c<2;c++){for(double& x:alpha[c]){x=r.d();if(x<=0||x>1e9)throw 2;}for(double& x:weights[c])x=r.d();normalized(weights[c].data(),13);}
 std::array<std::array<std::array<double,13>,13>,2> parts{};
 for(int c=0;c<2;c++){
  double total=0;for(double x:alpha[c])total+=x;
  for(int h=0;h<13;h++)for(int n=0;n<13;n++){
   int people=std::min(12,n+(c==0?carry:0));
   double q=h<12?(price<=h+1?0.9:0.1):std::clamp(0.8-0.075*(price-4),0.1,0.9);
   double a=2.0*q,b=2.0-a;std::array<double,13> row{};row[0]=1.0;
   for(int i=0;i<people;i++)row[0]*=(b+i)/(2.0+i);
   for(int s=0;s<people;s++)row[s+1]=row[s]*double(people-s)/(s+1)*(a+s)/(b+people-s-1);
   double sum=0;for(int s=0;s<=people;s++)sum+=row[s];
   for(int s=0;s<=people;s++){row[s]/=sum;parts[c][h][s]+=alpha[c][n]/total*row[s];}
  }
 }
 Forecast out{};
 for(int t=0;t<13;t++){
  std::array<std::array<double,13>,2> mass{};
  for(int c=0;c<2;c++){
   for(int h=0;h<13;h++)weights[c][h]=0.98*weights[c][h]+0.02*prior(h);
   for(int h=0;h<13;h++)for(int s=0;s<13;s++)mass[c][s]+=weights[c][h]*parts[c][h][s];
  }
  for(int l=0;l<13;l++)for(int v=0;v<13;v++)out[t][l+v]+=mass[0][l]*mass[1][v];
 }
 return out;
}
State operate(State s,int supply){
 int inputs=std::min({12,supply,int((s[0]+1e-9)/4)});s[0]-=inputs*4;s[1]+=inputs;s[3]-=inputs*4;
 int shifts=std::min({3,int((s[0]+1e-9)/6),int((s[1]+1e-9)/4)});
 s[0]-=shifts*6;s[1]-=shifts*4;s[2]+=shifts*6;s[3]-=shifts*6;return s;
}
double close(State& s,int price,double quantity){double sold=std::min(s[2],quantity);s[0]+=sold*price;s[2]-=sold;s[3]+=sold*price;double payout=std::max(0.0,std::min(s[3],s[0]-120.0));s[0]-=payout;s[3]-=payout;return payout;}
double mean(const Row& pmf,double stock){double v=0;for(int q=0;q<25;q++)v+=std::min(stock,double(q))*pmf[q];return v;}
double continuation(Reader& r,int price,int supply){
 State state;for(int i=0;i<4;i++){state[i]=r.d();if(std::abs(state[i])>1e9||(i<3&&state[i]<0))throw 2;}
 Forecast f;for(auto& row:f){for(auto& x:row)x=r.d();normalized(row.data(),25);}
 State first=operate(state,supply);int stock=std::min(24,int(first[2]));Row totals{};
 for(int q=0;q<25;q++)totals[std::min(q,stock)]+=f[0][q];
 std::array<double,13> means{};std::array<bool,13> present{};double value=0;
 for(int sold=0;sold<=stock;sold++){
  if(totals[sold]<1e-12)continue;
  State s=first;double branch=close(s,price,sold),discount=0.99;
  for(int t=1;t<13;t++){
   s=operate(s,supply);double expected;
   if(s[2]>=24){if(!present[t]){means[t]=mean(f[t],24);present[t]=true;}expected=means[t];}
   else expected=mean(f[t],s[2]);
   double payout=close(s,price,expected);branch+=discount*payout;discount*=0.99;
  }
  branch+=std::pow(0.99,12)*s[0];value+=totals[sold]*branch;
 }
 return value;
}
}
extern "C" int m20_cpp_compute(const uint8_t* input,size_t length,uint8_t* output,size_t capacity) noexcept {
 try{
  if(!input||!output||length<16)return 1;
  Reader r{input,length};if(r.u()!=0x4b30324d||r.u()!=1)return 1;
  uint32_t op=r.u(),count=r.u();if((op!=1&&op!=2)||count>100000)return 1;
  size_t stride=op==1?432:2648,values=op==1?325:1;
  if(length!=16+size_t(count)*stride||capacity!=16+size_t(count)*values*8)return 1;
  std::vector<double> out;out.reserve(count*values);
  for(uint32_t j=0;j<count;j++){
   uint32_t price=r.u(),aux=r.u();if(r.u()!=13||r.u()!=0||price<1||price>12||aux>12)return 2;
   if(op==1){auto f=forecast(r,int(price),int(aux));for(const auto& row:f)for(double x:row)out.push_back(x);}
   else out.push_back(continuation(r,int(price),int(aux)));
  }
  std::memcpy(output,input,16);for(size_t i=0;i<out.size();i++)write_double(output+16+i*8,out[i]);return 0;
 }catch(int status){return status;}catch(...){return 3;}
}
