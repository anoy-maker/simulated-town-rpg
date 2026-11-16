//! Pure ordered binary64 calculations; no Godot dependency, allocator ownership or world state.
type Forecast = [[f64; 25]; 13];
type State = [f64; 4];
struct Reader<'a> { data: &'a [u8], pos: usize }
impl Reader<'_> {
    fn u(&mut self) -> Result<u32, i32> {
        let bytes = self.data.get(self.pos..self.pos + 4).ok_or(1)?;
        self.pos += 4;
        Ok(u32::from_le_bytes(bytes.try_into().map_err(|_| 1)?))
    }
    fn d(&mut self) -> Result<f64, i32> {
        let bytes = self.data.get(self.pos..self.pos + 8).ok_or(1)?;
        self.pos += 8;
        let x = f64::from_le_bytes(bytes.try_into().map_err(|_| 1)?);
        if !x.is_finite() { return Err(2); }
        Ok(x)
    }
}
fn normalized(row: &[f64]) -> Result<(), i32> {
    let mut sum = 0.0;
    for &x in row { if x < 0.0 { return Err(2); } sum += x; }
    if (sum - 1.0).abs() > 1e-9 { return Err(2); } Ok(())
}
fn forecast(r: &mut Reader, price: i32, carry: usize) -> Result<Forecast, i32> {
    let mut alpha = [[0.0; 13]; 2]; let mut weights = [[0.0; 13]; 2];
    for c in 0..2 {
        for x in &mut alpha[c] { *x = r.d()?; if *x <= 0.0 || *x > 1e9 { return Err(2); } }
        for x in &mut weights[c] { *x = r.d()?; } normalized(&weights[c])?;
    }
    let mut parts = [[[0.0; 13]; 13]; 2];
    for c in 0..2 {
        let mut total = 0.0; for x in alpha[c] { total += x; }
        for h in 0..13 { for n in 0..13 {
            let people = (n + if c == 0 { carry } else { 0 }).min(12);
            let q = if h < 12 { if price <= h as i32 + 1 { 0.9 } else { 0.1 } }
                    else { (0.8 - 0.075 * (price - 4) as f64).clamp(0.1, 0.9) };
            let a = 2.0 * q; let b = 2.0 - a; let mut row = [0.0; 13]; row[0] = 1.0;
            for i in 0..people { row[0] *= (b + i as f64) / (2.0 + i as f64); }
            for s in 0..people { row[s+1] = row[s] * (people-s) as f64 / (s+1) as f64 * (a+s as f64) / (b+people as f64-s as f64-1.0); }
            let mut sum = 0.0; for &x in &row[..=people] { sum += x; }
            for (s, x) in row[..=people].iter_mut().enumerate() { *x /= sum; parts[c][h][s] += alpha[c][n] / total * *x; }
        } }
    }
    let mut out = [[0.0; 25]; 13];
    for day in &mut out {
        let mut mass = [[0.0; 13]; 2];
        for c in 0..2 {
            for h in 0..13 { weights[c][h] = 0.98 * weights[c][h] + 0.02 * if h < 12 { 0.8/12.0 } else { 0.2 }; }
            for h in 0..13 { for s in 0..13 { mass[c][s] += weights[c][h] * parts[c][h][s]; } }
        }
        for l in 0..13 { for v in 0..13 { day[l+v] += mass[0][l] * mass[1][v]; } }
    }
    Ok(out)
}
fn operate(mut s: State, supply: i32) -> State {
    let inputs = 12.min(supply).min(((s[0]+1e-9)/4.0) as i32);
    s[0] -= (inputs*4) as f64; s[1] += inputs as f64; s[3] -= (inputs*4) as f64;
    let shifts = 3.min(((s[0]+1e-9)/6.0) as i32).min(((s[1]+1e-9)/4.0) as i32);
    s[0] -= (shifts*6) as f64; s[1] -= (shifts*4) as f64; s[2] += (shifts*6) as f64; s[3] -= (shifts*6) as f64; s
}
fn close(s: &mut State, price: i32, quantity: f64) -> f64 {
    let sold = s[2].min(quantity); s[0] += sold*price as f64; s[2] -= sold; s[3] += sold*price as f64;
    let payout = s[3].min(s[0]-120.0).max(0.0); s[0] -= payout; s[3] -= payout; payout
}
fn mean(row: &[f64;25], stock: f64) -> f64 {
    let mut v = 0.0; for (q, &p) in row.iter().enumerate() { v += stock.min(q as f64)*p; } v
}
fn continuation(r: &mut Reader, price: i32, supply: i32) -> Result<f64, i32> {
    let mut state = [0.0;4];
    for (i,x) in state.iter_mut().enumerate() { *x=r.d()?; if x.abs()>1e9 || (i<3 && *x<0.0) { return Err(2); } }
    let mut f = [[0.0;25];13]; for row in &mut f { for x in row.iter_mut() { *x=r.d()?; } normalized(row)?; }
    let first = operate(state,supply); let stock = (first[2] as usize).min(24); let mut totals = [0.0;25];
    for q in 0..25 { totals[q.min(stock)] += f[0][q]; }
    let mut means = [None;13]; let mut value = 0.0;
    for (sold,&prob) in totals[..=stock].iter().enumerate() {
        if prob<1e-12 { continue; }
        let mut s=first; let mut branch=close(&mut s,price,sold as f64); let mut discount=0.99;
        for t in 1..13 {
            s=operate(s,supply);
            let expected = if s[2]>=24.0 { *means[t].get_or_insert_with(||mean(&f[t],24.0)) } else { mean(&f[t],s[2]) };
            let payout=close(&mut s,price,expected); branch += discount*payout; discount *= 0.99;
        }
        branch += 0.99_f64.powf(12.0)*s[0]; value += prob*branch;
    }
    Ok(value)
}
fn compute(input: &[u8], output: &mut [u8]) -> Result<(),i32> {
    let mut r=Reader{data:input,pos:0};
    if r.u()?!=0x4b30324d || r.u()?!=1 { return Err(1); }
    let op=r.u()?; let count=r.u()? as usize;
    if !(1..=2).contains(&op) || count>100000 { return Err(1); }
    let stride=if op==1 {432} else {2648}; let values=if op==1 {325} else {1};
    if input.len()!=16+count*stride || output.len()!=16+count*values*8 { return Err(1); }
    let mut out=Vec::with_capacity(count*values);
    for _ in 0..count {
        let price=r.u()?; let aux=r.u()?;
        if r.u()?!=13 || r.u()?!=0 || !(1..=12).contains(&price) || aux>12 {return Err(2);}
        if op==1 { for row in forecast(&mut r,price as i32,aux as usize)? {out.extend_from_slice(&row);} }
        else {out.push(continuation(&mut r,price as i32,aux as i32)?);}
    }
    output[..16].copy_from_slice(&input[..16]);
    for (i,x) in out.iter().enumerate() {output[16+i*8..24+i*8].copy_from_slice(&x.to_le_bytes());} Ok(())
}
/// # Safety
/// Caller supplies valid nonoverlapping buffers of the stated lengths, alive for
/// this call. No pointers are retained. Invalid numerical/schema input is safe.
#[no_mangle]
pub unsafe extern "C" fn m20_rust_compute(input:*const u8,length:usize,output:*mut u8,capacity:usize)->i32 {
    if input.is_null() || output.is_null() || length>isize::MAX as usize || capacity>isize::MAX as usize {return 1;}
    // Only unsafe operation: checked C caller borrows buffers; all math is safe Rust.
    let (src,dst)=unsafe{(std::slice::from_raw_parts(input,length),std::slice::from_raw_parts_mut(output,capacity))};
    compute(src,dst).err().unwrap_or(0)
}
