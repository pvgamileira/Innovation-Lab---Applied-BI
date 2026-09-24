import {
  PieChart, Pie, Cell, BarChart, Bar, XAxis, YAxis,
  Tooltip, ResponsiveContainer, ReferenceLine
} from 'recharts'

// ─── colour tokens ─────────────────────────────────────────────────────────
const C = {
  bg: '#07091a', card: '#0c1028', border: '#1e2650',
  red: '#e53935', green: '#43a047', green2: '#66bb6a',
  gray: '#757575', darkRed: '#9b1c1c', yellow: '#f9a825',
  blue: '#1e88e5', blue2: '#42a5f5', teal: '#00897b', purple: '#5c6bc0',
  cyan: '#00bcd4', orange: '#ef6c00', text: '#e8eaf6',
  muted: '#9fa8da', amber: '#ffc107', magenta: '#ab47bc',
}

// ─── tiny helpers ──────────────────────────────────────────────────────────
const Dot = ({ color }: { color: string }) => (
  <span style={{ display: 'inline-block', width: 9, height: 9, borderRadius: '50%', background: color, marginRight: 5, flexShrink: 0 }} />
)

const SectionTitle = ({ icon, title }: { icon: string; title: string }) => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 8 }}>
    <span style={{ color: C.cyan, fontSize: 11 }}>{icon}</span>
    <span style={{ fontSize: '0.62rem', fontWeight: 700, color: C.muted, textTransform: 'uppercase', letterSpacing: '0.04em' }}>{title}</span>
  </div>
)

const Card = ({ children, style }: { children: React.ReactNode; style?: React.CSSProperties }) => (
  <div style={{ background: C.card, border: `1px solid ${C.border}`, borderRadius: 6, padding: 10, ...style }}>
    {children}
  </div>
)

// ─── KPI card ──────────────────────────────────────────────────────────────
function KpiCard({ label, sublabel, value, delta, color, icon, highlight }: {
  label: string; sublabel: string; value: string; delta?: string;
  color: string; icon: string; highlight?: boolean
}) {
  const isNeg = delta?.startsWith('-') || delta?.startsWith('▼')
  return (
    <div style={{
      background: highlight ? '#1a1400' : C.card,
      border: `2px solid ${color}`,
      borderRadius: 6, padding: '10px 14px', flex: 1, minWidth: 0,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
        <div style={{ width: 32, height: 32, borderRadius: '50%', border: `2px solid ${color}`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 14, flexShrink: 0 }}>
          {icon}
        </div>
        <div>
          <div style={{ fontWeight: 800, fontSize: '0.85rem', color: C.text }}>{label}</div>
          <div style={{ fontSize: '0.6rem', color: C.muted }}>{sublabel}</div>
        </div>
      </div>
      <div style={{ fontSize: highlight ? '2.2rem' : '2rem', fontWeight: 900, color: color, lineHeight: 1 }}>{value}</div>
      {delta && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginTop: 4 }}>
          <span style={{ fontSize: '0.7rem', color: isNeg ? C.red : C.green, fontWeight: 700 }}>
            {delta}
          </span>
        </div>
      )}
    </div>
  )
}

// ─── Donut chart helper ────────────────────────────────────────────────────
function DonutChart({ data, innerLabel, innerSub, size = 130 }: {
  data: { name: string; value: number; color: string }[]
  innerLabel: string; innerSub?: string; size?: number
}) {
  return (
    <div style={{ position: 'relative', width: size, height: size, flexShrink: 0 }}>
      <ResponsiveContainer width="100%" height="100%">
        <PieChart>
          <Pie data={data} cx="50%" cy="50%" innerRadius={size * 0.3} outerRadius={size * 0.46}
            startAngle={90} endAngle={-270} dataKey="value" stroke="none">
            {data.map((d, i) => <Cell key={i} fill={d.color} />)}
          </Pie>
        </PieChart>
      </ResponsiveContainer>
      <div style={{
        position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center', pointerEvents: 'none',
      }}>
        <div style={{ fontSize: '0.65rem', color: C.muted, textAlign: 'center', lineHeight: 1.2 }}>Total</div>
        <div style={{ fontSize: '0.85rem', fontWeight: 800, color: C.text, textAlign: 'center', lineHeight: 1 }}>{innerLabel}</div>
        {innerSub && <div style={{ fontSize: '0.6rem', color: C.muted, textAlign: 'center' }}>{innerSub}</div>}
      </div>
    </div>
  )
}

// ─── Select dropdown ───────────────────────────────────────────────────────
function Select({ label, value }: { label: string; value: string }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
      <span style={{ fontSize: '0.58rem', color: C.muted, fontWeight: 600 }}>{label}</span>
      <select style={{
        background: '#111633', border: `1px solid ${C.border}`, borderRadius: 4,
        color: C.text, fontSize: '0.72rem', padding: '4px 28px 4px 8px', cursor: 'pointer',
        appearance: 'none', backgroundImage: `url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='10' height='6'%3E%3Cpath d='M0 0l5 6 5-6z' fill='%239fa8da'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'no-repeat', backgroundPosition: 'right 8px center',
      }}>
        <option>{value}</option>
      </select>
    </div>
  )
}

// ─── Legend row helper ─────────────────────────────────────────────────────
const LegRow = ({ color, label, value }: { color: string; label: string; value: string }) => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: '0.68rem', marginBottom: 2 }}>
    <Dot color={color} />
    <span style={{ color: C.muted, flex: 1 }}>{label}</span>
    <span style={{ color: C.text, fontWeight: 700 }}>{value}</span>
  </div>
)

// ─── MDZ radial-like card (simplified as positioned bubbles) ───────────────
function CriticalChart() {
  const items = [
    { label: 'Guarulhos', v: -12.6 }, { label: 'Osasco', v: -11.2 },
    { label: 'S. Bernardo', v: -10.4 }, { label: 'Santos', v: -9.8 },
    { label: 'Campinas', v: -8.7 }, { label: 'Sorocaba', v: -7.9 },
    { label: 'SJ Campos', v: -7.1 }, { label: 'Ribeirão Preto', v: -6.3 },
    { label: 'Santo André', v: -5.5 },
  ]
  const data = items.map(it => ({ name: it.label, value: Math.abs(it.v) }))
  return (
    <div style={{ display: 'flex', gap: 8, alignItems: 'center', height: '100%' }}>
      <div style={{ position: 'relative', width: 140, height: 140, flexShrink: 0 }}>
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie data={data} cx="50%" cy="50%" innerRadius={40} outerRadius={65}
              startAngle={90} endAngle={-270} dataKey="value" stroke="none">
              {data.map((_, i) => <Cell key={i} fill={i < 4 ? C.red : i < 7 ? '#e57373' : '#ef9a9a'} />)}
            </Pie>
          </PieChart>
        </ResponsiveContainer>
        <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', pointerEvents: 'none' }}>
          <div style={{ fontSize: '0.6rem', color: C.muted }}>Total</div>
          <div style={{ fontSize: '1.1rem', fontWeight: 900, color: C.text }}>9</div>
          <div style={{ fontSize: '0.58rem', color: C.muted }}>municípios</div>
        </div>
      </div>
      <div style={{ flex: 1 }}>
        {items.map((it, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: '0.65rem', marginBottom: 2 }}>
            <Dot color={i < 4 ? C.red : i < 7 ? '#e57373' : '#ef9a9a'} />
            <span style={{ color: C.muted, flex: 1 }}>{it.label}:</span>
            <span style={{ color: C.red, fontWeight: 700 }}>{it.v} p.p.</span>
          </div>
        ))}
      </div>
    </div>
  )
}

// ─── IAR bar chart ─────────────────────────────────────────────────────────
function IARChart() {
  const data = [
    { ano: '2018', votos: 6.8 },
    { ano: '2022', votos: 10.9 },
  ]
  return (
    <div style={{ height: 120 }}>
      <ResponsiveContainer width="100%" height="100%">
        <BarChart data={data} margin={{ top: 5, right: 5, left: -20, bottom: 0 }}>
          <XAxis dataKey="ano" tick={{ fontSize: 10, fill: C.muted }} axisLine={false} tickLine={false} />
          <YAxis tick={{ fontSize: 10, fill: C.muted }} axisLine={false} tickLine={false} domain={[0, 25]} ticks={[0, 5, 10, 15, 20]} />
          <ReferenceLine y={3} stroke={C.red} strokeDasharray="4 3" label={{ value: '-3,p.p. gatilho', fill: C.red, fontSize: 9, position: 'right' }} />
          <Bar dataKey="votos" fill={C.blue} radius={[3, 3, 0, 0]} barSize={28}>
            <Cell fill={C.blue2} />
            <Cell fill={C.blue} />
          </Bar>
          <Tooltip
            contentStyle={{ background: C.card, border: `1px solid ${C.border}`, borderRadius: 4, fontSize: 11 }}
            formatter={(v) => [`${v}%`, 'Votos alienados']}
          />
        </BarChart>
      </ResponsiveContainer>
      <div style={{ display: 'flex', justifyContent: 'space-around', fontSize: '0.65rem', marginTop: 2 }}>
        <span style={{ color: C.muted }}>6,8%</span>
        <span style={{ color: C.muted }}>10,9%</span>
      </div>
    </div>
  )
}

// ─── RML bar chart ─────────────────────────────────────────────────────────
function RMLChart() {
  const data = [
    { ano: '2018', nominal: 32, legenda: 68 },
    { ano: '2022', nominal: 24, legenda: 76 },
  ]
  return (
    <div style={{ height: 130 }}>
      <div style={{ display: 'flex', gap: 12, marginBottom: 4, fontSize: '0.62rem' }}>
        <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}><Dot color={C.green} />Votos Nominais</span>
        <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}><Dot color={C.blue} />Votos de Legenda</span>
      </div>
      <ResponsiveContainer width="100%" height={110}>
        <BarChart data={data} margin={{ top: 5, right: 5, left: -28, bottom: 0 }}>
          <XAxis dataKey="ano" tick={{ fontSize: 10, fill: C.muted }} axisLine={false} tickLine={false} />
          <YAxis tick={{ fontSize: 10, fill: C.muted }} axisLine={false} tickLine={false}
            domain={[0, 100]} ticks={[0, 25, 50, 75, 100]}
            tickFormatter={(v) => `${v}%`} />
          <Bar dataKey="legenda" fill={C.blue} stackId="a" />
          <Bar dataKey="nominal" fill={C.green} stackId="a" radius={[3, 3, 0, 0]} />
          <Tooltip
            contentStyle={{ background: C.card, border: `1px solid ${C.border}`, borderRadius: 4, fontSize: 11 }}
            formatter={(v, name) => [`${v}%`, name === 'nominal' ? 'Nominais' : 'Legenda']}
          />
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}

// ─── PDL stacked horizontal bar ────────────────────────────────────────────
function PDLChart() {
  const rows = [
    { faixa: '18 – 24', fund: 16, medio: 66, sup: 28 },
    { faixa: '25 – 34', fund: 16, medio: 55, sup: 20 },
    { faixa: '35 – 44', fund: 16, medio: 50, sup: 21 },
    { faixa: '45 – 59', fund: 11, medio: 45, sup: 65 },
    { faixa: '60+', fund: 6, medio: 32, sup: 66 },
  ]
  return (
    <div style={{ fontSize: '0.65rem' }}>
      <div style={{ display: 'flex', gap: 12, marginBottom: 6 }}>
        {[['Fundamental', C.yellow], ['Médio', C.blue], ['Superior', C.green]].map(([l, c]) => (
          <span key={l as string} style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
            <Dot color={c as string} />{l}
          </span>
        ))}
      </div>
      {rows.map((r) => (
        <div key={r.faixa} style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
          <div style={{ width: 38, color: C.muted, textAlign: 'right', flexShrink: 0, fontSize: '0.62rem' }}>{r.faixa}</div>
          <div style={{ flex: 1, display: 'flex', height: 16, borderRadius: 3, overflow: 'hidden' }}>
            <div style={{ width: `${r.fund}%`, background: C.yellow, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '0.58rem', color: '#000', fontWeight: 700 }}>{r.fund}%</div>
            <div style={{ width: `${r.medio}%`, background: C.blue, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '0.58rem', color: '#fff', fontWeight: 700 }}>{r.medio}%</div>
            <div style={{ width: `${r.sup}%`, background: C.green, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '0.58rem', color: '#fff', fontWeight: 700 }}>{r.sup}%</div>
          </div>
        </div>
      ))}
      <div style={{ display: 'flex', justifyContent: 'space-between', color: C.muted, fontSize: '0.58rem', marginTop: 2 }}>
        {['0%', '20%', '40%', '60%', '80%', '100%'].map(v => <span key={v}>{v}</span>)}
      </div>
    </div>
  )
}

// ─── Table ─────────────────────────────────────────────────────────────────
function AlertTable() {
  const rows = [
    { zona: 129, local: 'Escola Estadual', votos: '12.842', ms: '24,6%', alerta: true },
    { zona: 456, local: 'UBS Centro', votos: '8.763', ms: '21,3%', alerta: true },
    { zona: 789, local: 'EMEF Jardim das Flores', votos: '6.521', ms: '18,7%', alerta: false },
    { zona: 321, local: 'Colégio Municipal', votos: '5.990', ms: '16,4%', alerta: false },
    { zona: 654, local: 'Escola Estadual', votos: '4.873', ms: '14,2%', alerta: true },
    { zona: 987, local: 'IFSP Campinas', votos: '4.221', ms: '12,8%', alerta: false },
  ]
  const th = { fontSize: '0.62rem', color: C.muted, fontWeight: 700, padding: '4px 8px', borderBottom: `1px solid ${C.border}`, textAlign: 'left' as const }
  const td = { fontSize: '0.68rem', color: C.text, padding: '5px 8px', borderBottom: `1px solid #141830` }
  return (
    <div style={{ overflowX: 'auto' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
        <thead>
          <tr>
            <th style={th}>Zona</th>
            <th style={th}>Local</th>
            <th style={{ ...th, textAlign: 'right' }}>Votos</th>
            <th style={{ ...th, textAlign: 'right' }}>Market Share</th>
            <th style={{ ...th, textAlign: 'center' }}>Alerta</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r, i) => (
            <tr key={i} style={{ background: i % 2 === 0 ? '#0d1230' : 'transparent' }}>
              <td style={{ ...td, color: C.muted }}>{r.zona}</td>
              <td style={td}>{r.local}</td>
              <td style={{ ...td, textAlign: 'right' }}>{r.votos}</td>
              <td style={{ ...td, textAlign: 'right' }}>{r.ms}</td>
              <td style={{ ...td, textAlign: 'center' }}>
                {r.alerta
                  ? <span style={{ background: C.red, color: '#fff', fontSize: '0.6rem', fontWeight: 700, padding: '2px 8px', borderRadius: 10 }}>Alerta</span>
                  : <span style={{ color: C.muted }}>–</span>}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

// ─── App ───────────────────────────────────────────────────────────────────
export default function App() {
  // donut data sets
  const distMun = [
    { name: 'Crescimento', value: 22, color: C.green },
    { name: 'Estável', value: 15, color: C.gray },
    { name: 'Queda', value: 45, color: C.red },
    { name: 'Críticos', value: 18, color: C.darkRed },
  ]
  const mdzMain = [
    { name: 'Marília 33,5%', value: 33.5, color: C.green2 },
    { name: 'Pres.Prudente 31%', value: 24.6, color: '#a5d6a7' },
    { name: 'Bauru 26,6%', value: 16.6, color: C.teal },
    { name: 'Franca 24,6%', value: 16.6, color: '#80cbc4' },
    { name: 'Jundiaí 22,1%', value: 8.7, color: C.cyan },
  ]
  const delvData = [
    { name: 'Grande ABC', value: 25, color: C.blue },
    { name: 'Capital/RMSP', value: 30, color: C.purple },
    { name: 'Interior', value: 30, color: C.green },
    { name: 'Litoral', value: 15, color: C.amber ?? C.yellow },
  ]
  const icfData = [
    { name: 'Ana Carolina Serra', value: 27.6, color: C.cyan },
    { name: 'Outros PSDB', value: 32.4, color: C.blue },
    { name: 'Adversários', value: 40.0, color: C.yellow },
  ]
  const tdlRegData = [
    { name: 'Grande ABC', value: 24, color: C.purple },
    { name: 'Capital/RMSP', value: 38, color: C.magenta ?? C.purple },
    { name: 'Interior', value: 28, color: C.green },
    { name: 'Litoral', value: 10, color: C.cyan },
  ]

  const g = (s: string) => ({ display: 'grid', gridTemplateColumns: s, gap: 8 })

  return (
    <div className="dashboard" style={{ background: C.bg, minHeight: '100vh', padding: 0 }}>

      {/* ── HEADER ── */}
      <div style={{ background: '#070a1e', borderBottom: `1px solid ${C.border}`, padding: '8px 16px', display: 'flex', alignItems: 'center', gap: 16 }}>
        {/* Logo + title */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: 1 }}>
          <div style={{ width: 48, height: 48, borderRadius: '50%', background: 'linear-gradient(135deg,#1565c0,#00bcd4)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 24, flexShrink: 0 }}>🦜</div>
          <div>
            <div style={{ fontSize: '1.15rem', fontWeight: 900, color: C.text, letterSpacing: '-0.01em' }}>
              PANORAMA ELEITORAL SP <span style={{ color: C.cyan }}>•</span> REELEIÇÃO 2026
            </div>
            <div style={{ fontSize: '0.68rem', color: C.muted }}>
              Deputada Estadual Ana Carolina Serra - PSDB-SP &nbsp;|&nbsp; Eleições 2022 vs 2018
            </div>
          </div>
        </div>
        {/* Selects */}
        <div style={{ display: 'flex', gap: 12 }}>
          <Select label="Pleito" value="2018/2022" />
          <Select label="Município" value="Todos" />
          <Select label="Zona Eleitoral" value="Todos" />
          <Select label="Cargo" value="Deputado Estadual" />
        </div>
      </div>

      <div style={{ padding: '8px 12px', display: 'flex', flexDirection: 'column', gap: 8 }}>

        {/* ── ROW 1: KPI cards ── */}
        <div style={{ display: 'flex', gap: 8 }}>
          <KpiCard icon="📉" label="VHMS" sublabel="Variação de Market Share" value="-4,2 p.p." delta="▼ Queda" color={C.red} />
          <KpiCard icon="🎯" label="TDL" sublabel="Taxa de Dominância" value="31,8%" delta="▲ +2,7 p.p." color={C.blue} />
          <KpiCard icon="📍" label="MDZ" sublabel="Swing Zones" value="23 zonas" delta="⚠ Atenção" color={C.yellow} highlight />
          <KpiCard icon="👥" label="TABF" sublabel="Abstenção Base Fiel" value="18,4%" delta="▼ -3,1 p.p." color={C.teal} />
          <KpiCard icon="🔗" label="IDF" sublabel="Dependência da Federação" value="64,2%" delta="▲ +5,6 p.p." color={C.purple} />
        </div>

        {/* ── ROW 2: 3 wide panels ── */}
        <div style={g('1fr 1fr 1fr')}>

          {/* Distribuição Municípios */}
          <Card>
            <SectionTitle icon="⚙" title="Distribuição dos Municípios – Market Share (2022 vs 2018)" />
            <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
              <DonutChart data={distMun} innerLabel="645" innerSub="municípios" size={140} />
              <div style={{ flex: 1 }}>
                <LegRow color={C.green} label="Crescimento (> 0 p.p.):" value="22%" />
                <LegRow color={C.gray} label="Estável (−0,5 a +0,5 p.p.):" value="15%" />
                <LegRow color={C.red} label="Queda (< −0,5 p.p.):" value="45%" />
                <LegRow color={C.darkRed} label="Municípios Críticos (queda > 5 p.p.):" value="18%" />
              </div>
            </div>
          </Card>

          {/* MDZ main */}
          <Card>
            <SectionTitle icon="⚙" title="MDZ – Municípios com Dominação (Maior Margem de Vitória)" />
            <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
              <DonutChart data={mdzMain} innerLabel="8" innerSub="municípios" size={140} />
              <div style={{ flex: 1 }}>
                <LegRow color={C.green2} label="Marília:" value="33,5%" />
                <LegRow color="#a5d6a7" label="Presidente Prudente:" value="31,0%" />
                <LegRow color={C.teal} label="Bauru:" value="26,6%" />
                <LegRow color="#80cbc4" label="Franca:" value="24,6%" />
                <LegRow color={C.cyan} label="Jundiaí:" value="22,1%" />
                <LegRow color={C.blue} label="Piracicaba:" value="19,4%" />
                <LegRow color="#b39ddb" label="Araçatuba:" value="18,5%" />
                <LegRow color="#ce93d8" label="São Carlos:" value="16,9%" />
              </div>
            </div>
          </Card>

          {/* Municípios Críticos */}
          <Card>
            <SectionTitle icon="⚙" title="Municípios Críticos – Market Share (Queda > 5 p.p.)" />
            <CriticalChart />
          </Card>
        </div>

        {/* ── ROW 3: 5 smaller panels ── */}
        <div style={g('1fr 1fr 1fr 1fr 1fr')}>

          {/* MDZ smaller */}
          <Card>
            <SectionTitle icon="⚙" title="MDZ – Municípios com Dominação" />
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
              <DonutChart data={mdzMain} innerLabel="8" innerSub="municípios" size={110} />
              <div style={{ width: '100%' }}>
                {[['Marília', '33,5%', C.green2], ['Pres. Prudente', '27,0%', '#a5d6a7'], ['Bauru', '24,6%', C.teal], ['Franca', '23,6%', '#80cbc4'], ['Jundiaí', '21,4%', C.cyan], ['Piracicaba', '19,4%', C.blue], ['Araçatuba', '18,5%', '#b39ddb'], ['São Carlos', '16,9%', '#ce93d8']].map(([l, v, c]) => (
                  <div key={l as string} style={{ display: 'flex', gap: 4, fontSize: '0.6rem', marginBottom: 1 }}>
                    <Dot color={c as string} />
                    <span style={{ color: C.muted, flex: 1 }}>{l}</span>
                    <span style={{ color: C.text, fontWeight: 700 }}>{v}</span>
                  </div>
                ))}
              </div>
            </div>
          </Card>

          {/* RML */}
          <Card>
            <SectionTitle icon="⚙" title="RML – Migração Nominal vs Legenda" />
            <RMLChart />
            <div style={{ marginTop: 6, fontSize: '0.65rem', display: 'flex', justifyContent: 'space-between' }}>
              <div>
                <div style={{ color: C.muted, fontSize: '0.58rem' }}>Saldo absoluto (crescimento)/</div>
                <div style={{ color: C.green, fontWeight: 800 }}>+182.416</div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ color: C.muted, fontSize: '0.58rem' }}>retração</div>
                <div style={{ color: C.red, fontWeight: 800 }}>-96.722</div>
              </div>
            </div>
          </Card>

          {/* DELV */}
          <Card>
            <SectionTitle icon="⚙" title="DELV – Municípios IVM Vulneráveis por Região" />
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
              <DonutChart data={delvData} innerLabel="100" innerSub="municípios" size={110} />
              <div style={{ width: '100%' }}>
                <LegRow color={C.blue} label="Grande ABC:" value="25%" />
                <LegRow color={C.purple} label="Capital/RMSP:" value="30%" />
                <LegRow color={C.green} label="Interior:" value="30%" />
                <LegRow color={C.yellow} label="Litoral:" value="15%" />
              </div>
            </div>
            <div style={{ fontSize: '0.55rem', color: C.muted, marginTop: 4, lineHeight: 1.4 }}>
              QT_APTOS no Local de Votação, aplicado apenas nos municípios com IVM Vulnerável/
            </div>
          </Card>

          {/* IAR */}
          <Card>
            <SectionTitle icon="⚙" title="IAR – Votos Alienados" />
            <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: '0.6rem', marginBottom: 4 }}>
              <Dot color={C.blue} />
              <span style={{ color: C.muted }}>Votos alienados (%)</span>
              <span style={{ color: C.red, marginLeft: 8 }}>- - - -3,p.p. gatilho</span>
            </div>
            <IARChart />
          </Card>

          {/* ICF */}
          <Card>
            <SectionTitle icon="⚙" title="ICF – Canibalização Grande ABC/RMSP" />
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
              <div style={{ position: 'relative' }}>
                <DonutChart data={icfData} innerLabel="27,6%" innerSub="ICF" size={110} />
              </div>
              <div style={{ width: '100%' }}>
                <LegRow color={C.cyan} label="Ana Carolina Serra:" value="27,6%" />
                <LegRow color={C.blue} label="Outros PSDB:" value="32,4%" />
                <LegRow color={C.yellow} label="Adversários:" value="40,0%" />
              </div>
            </div>
          </Card>
        </div>

        {/* ── ROW 4: TDL + PDL + table ── */}
        <div style={g('1fr 2fr 2fr')}>

          {/* TDL Locais */}
          <Card>
            <SectionTitle icon="⚙" title="TDL – Locais com Dominação > 25% por Região" />
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
              <DonutChart data={tdlRegData} innerLabel="9,2" innerSub="locais" size={120} />
              <div style={{ width: '100%' }}>
                <LegRow color={C.purple} label="Grande ABC:" value="24%" />
                <LegRow color={C.magenta ?? C.purple} label="Capital/RMSP:" value="38%" />
                <LegRow color={C.green} label="Interior:" value="28%" />
                <LegRow color={C.cyan} label="Litoral:" value="10%" />
              </div>
            </div>
          </Card>

          {/* PDL */}
          <Card>
            <SectionTitle icon="⚙" title="PDL – Perfil Demográfico: Faixa Etária X Escolaridade" />
            <div style={{ display: 'flex', gap: 12 }}>
              <div style={{ flex: 1 }}><PDLChart /></div>
              {/* callout box */}
              <div style={{
                background: '#1a1200', border: `2px solid ${C.yellow}`, borderRadius: 6,
                padding: '12px 14px', minWidth: 140, display: 'flex', flexDirection: 'column',
                alignItems: 'center', justifyContent: 'center', gap: 4,
              }}>
                <span style={{ color: C.yellow, fontSize: '1rem' }}>⭐</span>
                <div style={{ fontSize: '0.6rem', color: C.muted, textAlign: 'center' }}>Modal (pior desempenho)</div>
                <div style={{ fontWeight: 900, fontSize: '1.1rem', color: C.yellow, textAlign: 'center', lineHeight: 1.2 }}>35 – 44 anos</div>
                <div style={{ fontWeight: 700, fontSize: '0.8rem', color: C.yellow, textAlign: 'center' }}>Ensino Médio</div>
                <div style={{ fontSize: '0.7rem', color: C.text, fontWeight: 600, textAlign: 'center' }}>44% do volume</div>
              </div>
            </div>
          </Card>

          {/* Alert table */}
          <Card>
            <AlertTable />
          </Card>
        </div>

      </div>
    </div>
  )
}
