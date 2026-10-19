use extendr_api::prelude::*;
use rayon::prelude::*;
use rstar::{RTree, primitives::GeomWithData};

struct IndexWIdx(RTree<GeomWithData<[f64; 2], usize>>);

#[extendr]
fn build_index_seq(x: Doubles, y: Doubles) -> ExternalPtr<IndexWIdx> {
    ExternalPtr::new(IndexWIdx(rstar::RTree::bulk_load(
        x.iter()
            .zip(y.iter())
            .enumerate()
            .map(|(i, (x, y))| GeomWithData::new([x.0, y.0], i))
            .collect(),
    )))
}

fn calc(a_i: f64, a_j: f64, a_c: (f64, f64), b_c: (f64, f64), s: f64) -> (f64, f64) {
    let dist_x = a_c.0 - b_c.0;
    let dist_y = a_c.1 - b_c.1;
    let dist = ((dist_x * dist_x) + (dist_y * dist_y)).sqrt();
    let w = (-dist / s).exp();

    (w * a_i * a_j, w)
}

#[extendr]
fn eop_seq(
    a: Doubles,
    b: Doubles,
    a_x: Doubles,
    a_y: Doubles,
    b_x: Doubles,
    b_y: Doubles,
    scale_fact: f64,
) -> Result<[f64; 2], String> {
    if (a.len() != a_x.len()) || (a.len() != a_y.len()) {
        return Err("a, a_x, and a_y must have the same length".to_string());
    }
    if (b.len() != b_x.len()) || (b.len() != b_y.len()) {
        return Err("b, b_x, and b_y must have the same length".to_string());
    }

    Ok(a.iter()
        .zip(a_x.iter())
        .zip(a_y.iter())
        .fold([0., 0.], |[o_c, o_w], ((a_i, a_x), a_y)| {
            b.iter().zip(b_x.iter()).zip(b_y.iter()).fold(
                [o_c, o_w],
                |[o_c, o_w], ((b_j, b_x), b_y)| {
                    let (c, w) = calc(a_i.0, b_j.0, (a_x.0, a_y.0), (b_x.0, b_y.0), scale_fact);

                    [o_c + c, o_w + w]
                },
            )
        }))
}

#[extendr]
fn eop_par(
    a: Doubles,
    b: Doubles,
    a_x: Doubles,
    a_y: Doubles,
    b_x: Doubles,
    b_y: Doubles,
    scale_fact: f64,
) -> Result<[f64; 2], String> {
    if (a.len() != a_x.len()) || (a.len() != a_y.len()) {
        return Err("a, a_x, and a_y must have the same length".to_string());
    }
    if (b.len() != b_x.len()) || (b.len() != b_y.len()) {
        return Err("b, b_x, and b_y must have the same length".to_string());
    }

    let (b, b_x, b_y) = (&b[..], &b_x[..], &b_y[..]);

    Ok(a.par_iter()
        .zip(a_x.par_iter())
        .zip(a_y.par_iter())
        .map(|((a_i, a_x), a_y)| {
            b.iter().zip(b_x.iter()).zip(b_y.iter()).fold(
                [0., 0.],
                |[o_c, o_w], ((b_j, b_x), b_y)| {
                    let (c, w) = calc(a_i.0, b_j.0, (a_x.0, a_y.0), (b_x.0, b_y.0), scale_fact);

                    [o_c + c, o_w + w]
                },
            )
        })
        .reduce(|| [0., 0.], |[a1, a2], [c1, c2]| [a1 + c1, a2 + c2]))
}

#[extendr]
fn eopi_seq(
    a: Doubles,
    b: Doubles,
    a_x: Doubles,
    a_y: Doubles,
    b_index: ExternalPtr<IndexWIdx>,
    scale_fact: f64,
    #[extendr(default = "1e-8")] err: f64,
) -> Result<[f64; 2], String> {
    if (a.len() != a_x.len()) || (a.len() != a_y.len()) {
        return Err("a, a_x, and a_y must have the same length".to_string());
    }
    if b.len() != b_index.0.size() {
        return Err("b and b_index must have the length".to_string());
    }

    let rad = -err.ln() * scale_fact;
    let radp2 = (rad * rad).min(f64::MAX); // gracefully deal w/ NaNs by just setting radius to f64 maximum

    Ok(a.iter()
        .zip(a_x.iter())
        .zip(a_y.iter())
        .fold([0., 0.], |[o_c, o_w], ((a_i, a_x), a_y)| {
            b_index
                .0
                .locate_within_distance([a_x.0, a_y.0], radp2)
                .fold([o_c, o_w], |[o_c, o_w], g_y| {
                    let &[b_x, b_y] = g_y.geom();
                    let (c, w) = calc(a_i.0, b[g_y.data].0, (a_x.0, a_y.0), (b_x, b_y), scale_fact);

                    [o_c + c, o_w + w]
                })
        }))
}

#[extendr]
fn eopi_par(
    a: Doubles,
    b: Doubles,
    a_x: Doubles,
    a_y: Doubles,
    b_index: ExternalPtr<IndexWIdx>,
    scale_fact: f64,
    #[extendr(default = "1e-8")] err: f64,
) -> Result<[f64; 2], String> {
    if (a.len() != a_x.len()) || (a.len() != a_y.len()) {
        return Err("a, a_x, and a_y must have the same length".to_string());
    }
    if b.len() != b_index.0.size() {
        return Err("b and b_index must have the length".to_string());
    }

    let rad = -err.ln() * scale_fact;
    let radp2 = (rad * rad).min(f64::MAX); // gracefully deal w/ NaNs by just setting radius to f64 maximum
    let (b, b_index) = (&b[..], b_index.as_ref());

    Ok(a.par_iter()
        .zip(a_x.par_iter())
        .zip(a_y.par_iter())
        .map(|((a_i, a_x), a_y)| {
            b_index
                .0
                .locate_within_distance([a_x.0, a_y.0], radp2)
                .fold([0., 0.], |[o_c, o_w], g_y| {
                    let &[b_x, b_y] = g_y.geom();
                    let (c, w) = calc(a_i.0, b[g_y.data].0, (a_x.0, a_y.0), (b_x, b_y), scale_fact);

                    [o_c + c, o_w + w]
                })
        })
        .reduce(|| [0., 0.], |[a1, a2], [c1, c2]| [a1 + c1, a2 + c2]))
}

extendr_module! {
    mod usci;
    fn eop_seq;
    fn eop_par;
    fn eopi_seq;
    fn eopi_par;
    fn build_index_seq;
}
