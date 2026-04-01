<template>
  <div class="verdict-view">
    <!-- 顶部导航 -->
    <header class="verdict-header">
      <button class="btn-back" @click="router.back()">← 返回庭审</button>
      <div class="header-title">
        <span class="header-icon">⚖</span>
        <div>
          <h1 class="header-h1">判决结果预测报告</h1>
          <span class="header-sub">{{ caseName || '法庭庭审模拟' }}</span>
        </div>
      </div>
      <div class="header-right">
        <span class="status-dot" :class="statusDotClass" />
        <span class="status-label">{{ statusLabel }}</span>
        <button v-if="phase === 'done'" class="btn-export" @click="copyReport">复制全文</button>
        <button v-if="phase === 'done'" class="btn-rerun" @click="confirmRerun">重新执行</button>
      </div>
    </header>

    <!-- ===== 生成中 ===== -->
    <div v-if="phase === 'generating'" class="center-area">
      <div class="gen-card">
        <div class="spinner" />
        <h2>AI 正在生成判决预测报告</h2>
        <p class="gen-hint">综合分析庭审发言、证据质证与法庭辩论，预计需要 1~3 分钟</p>
        <div class="progress-track"><div class="progress-fill" :style="{ width: progressPct + '%' }" /></div>
        <span class="progress-text">{{ progressPct }}%</span>
        <div v-if="logLines.length" class="gen-logs">
          <div v-for="(line, i) in logLines.slice(-8)" :key="i" class="log-line">{{ line }}</div>
        </div>
      </div>
    </div>

    <!-- ===== 未开始 ===== -->
    <div v-else-if="phase === 'idle'" class="center-area">
      <div class="idle-card">
        <div class="idle-icon">⚖</div>
        <h2>生成判决预测报告</h2>
        <p>基于本次庭审模拟全部发言记录，AI 将综合分析各方陈述、证据质证与法庭辩论，输出结构化判决结果预测报告，供法律研究与教学参考。</p>
        <button class="btn-generate" @click="startGenerate">开始生成</button>
      </div>
    </div>

    <!-- ===== 查询已有报告中 ===== -->
    <div v-else-if="phase === 'checking'" class="center-area">
      <div class="idle-card">
        <div class="spinner" style="margin:0 auto 16px" />
        <h2>正在加载已有报告...</h2>
      </div>
    </div>

    <!-- ===== 报告内容 ===== -->
    <div v-else-if="phase === 'done'" class="report-area">

      <!-- 左侧目录 -->
      <div class="report-toc">
        <div class="toc-title">目录</div>
        <ul class="toc-list">
          <!-- 固定的仪表盘锚点 -->
          <li class="toc-item toc-level-1" :class="{ active: activeTocId === '__dashboard' }">
            <a href="#__dashboard" @click.prevent="scrollToSection('__dashboard')">判决预测摘要</a>
          </li>
          <li v-for="(item, i) in tocItems" :key="i"
            class="toc-item"
            :class="['toc-level-' + item.level, { active: activeTocId === item.id }]"
          >
            <a :href="'#' + item.id" @click.prevent="scrollToSection(item.id)">{{ item.text }}</a>
          </li>
        </ul>
      </div>

      <!-- 右侧主内容 -->
      <div class="report-main" ref="reportMainRef">

        <!-- ===== 判决预测仪表盘 ===== -->
        <div class="dashboard" id="__dashboard">

          <!-- Dashboard 折叠 Header -->
          <div class="dashboard-header" @click="isDashboardCollapsed = !isDashboardCollapsed">
            <span class="dh-title">⚖ 判决预测仪表盘</span>
            <span class="rbh-toggle">{{ isDashboardCollapsed ? '展开' : '折叠' }}</span>
            <span class="rbh-chevron" :class="{ open: !isDashboardCollapsed }">▾</span>
          </div>

          <div class="dashboard-body" v-show="!isDashboardCollapsed">
            <!-- 案件基本信息条 -->
            <div class="case-info-bar">
              <span class="ci-item"><span class="ci-label">案件</span><span class="ci-val">{{ caseName || '—' }}</span></span>
              <span class="ci-sep" />
              <span class="ci-item"><span class="ci-label">类型</span><span class="ci-val">{{ caseTypeText }}</span></span>
              <span class="ci-sep" />
              <span class="ci-item">
                <span class="ci-label">置信度</span>
                <span class="ci-val conf-badge" :class="'conf-' + (verdictData?.confidence_level || 'low')">
                  {{ confidenceText }}
                </span>
              </span>
              <span class="ci-sep" />
              <span class="ci-item"><span class="ci-label">生成时间</span><span class="ci-val">{{ generatedAt }}</span></span>
            </div>

            <!-- 胜诉概率主视觉 -->
            <div class="prob-section">
              <div class="prob-side prob-plaintiff">
                <div class="prob-role">{{ plaintiffLabel }}</div>
                <div class="prob-pct" style="color:#3b82f6">{{ plaintiffPct }}%</div>
                <div class="prob-desc">胜诉概率</div>
              </div>

              <div class="prob-bar-wrap">
                <div class="prob-bar-track">
                  <div class="prob-fill prob-fill-p" :style="{ width: plaintiffPct + '%' }" />
                  <div class="prob-fill prob-fill-d" :style="{ width: defendantPct + '%', right: 0 }" />
                  <div class="prob-mid-line" />
                </div>
                <div class="prob-bar-labels">
                  <span>0%</span>
                  <span>50%</span>
                  <span>100%</span>
                </div>
              </div>

              <div class="prob-side prob-defendant">
                <div class="prob-role">{{ defendantLabel }}</div>
                <div class="prob-pct" style="color:#ef4444">{{ defendantPct }}%</div>
                <div class="prob-desc">胜诉概率</div>
              </div>
            </div>

            <!-- 三栏：关键因素 / 赔偿区间 / 法律风险 -->
            <div class="detail-grid">

              <!-- 核心决定因素 -->
              <div class="detail-card">
                <div class="detail-card-title">
                  <span class="dct-icon dct-blue">⚖</span>核心决定因素
                </div>
                <div v-if="!verdictData?.key_factors?.length" class="detail-empty">
                  <span class="empty-icon">—</span> 暂无数据
                </div>
                <ul v-else class="factor-list">
                  <li v-for="(f, i) in verdictData.key_factors" :key="i" class="factor-item">
                    <span class="fi-num">{{ i + 1 }}</span>
                    <span class="fi-text">{{ f }}</span>
                  </li>
                </ul>
              </div>

              <!-- 预期赔偿区间 -->
              <div class="detail-card">
                <div class="detail-card-title">
                  <span class="dct-icon dct-green">¥</span>预期赔偿区间
                </div>
                <div v-if="!verdictData?.compensation_range" class="detail-empty">
                  <span class="empty-icon">—</span>
                  {{ verdictData?.verdict_type?.startsWith('criminal') ? '刑事案件，不适用赔偿' : '暂无数据' }}
                </div>
                <div v-else class="comp-display">
                  <div class="comp-range">
                    <span class="comp-num">{{ fmtAmount(verdictData.compensation_range.min) }}</span>
                    <span class="comp-wave">～</span>
                    <span class="comp-num">{{ fmtAmount(verdictData.compensation_range.max) }}</span>
                    <span class="comp-cny">{{ verdictData.compensation_range.currency || 'CNY' }}</span>
                  </div>
                  <div v-if="verdictData.compensation_range.note" class="comp-note">
                    {{ verdictData.compensation_range.note }}
                  </div>
                  <div class="comp-bar-wrap">
                    <div class="comp-bar" />
                  </div>
                </div>
              </div>

              <!-- 法律风险提示 -->
              <div class="detail-card">
                <div class="detail-card-title">
                  <span class="dct-icon dct-orange">⚠</span>法律风险提示
                </div>
                <div v-if="!verdictData?.legal_risks?.length" class="detail-empty">
                  <span class="empty-icon">—</span> 暂无数据
                </div>
                <ul v-else class="risk-list">
                  <li v-for="(r, i) in verdictData.legal_risks" :key="i" class="risk-item">
                    <span class="ri-dot" />
                    <span class="ri-text">{{ r }}</span>
                  </li>
                </ul>
              </div>

            </div>
          </div>

        </div>

        <!-- 免责声明 — 独立于 dashboard，始终紧跟其下 -->
        <div class="disclaimer">
          本预测结果基于 AI 多智能体庭审模拟生成，仅供学术研究与教学参考，不代表真实司法判决，不构成任何法律建议。如需法律指导，请咨询专业律师。
        </div>

        <!-- ===== 报告正文 ===== -->
        <div class="report-body" :class="{ collapsed: isReportBodyCollapsed }">
          <div class="report-body-header" @click="isReportBodyCollapsed = !isReportBodyCollapsed">
            <span class="rbh-icon">📄</span>
            <span class="rbh-title">分析报告全文</span>
            <span class="rbh-hint">内容由 AI 依据庭审记录生成</span>
            <span class="rbh-toggle">{{ isReportBodyCollapsed ? '展开' : '折叠' }}</span>
            <span class="rbh-chevron" :class="{ open: !isReportBodyCollapsed }">▾</span>
          </div>
          <div class="markdown-content" ref="markdownRef" v-show="!isReportBodyCollapsed">
            <div v-if="!renderedMarkdown" style="color:#475569;font-style:italic">报告内容为空</div>
            <div v-else v-html="renderedMarkdown" />
          </div>
        </div>

      </div>
    </div>

    <!-- ===== 错误 ===== -->
    <div v-else-if="phase === 'error'" class="center-area">
      <div class="idle-card">
        <div class="idle-icon">⚠</div>
        <h2>生成失败</h2>
        <p>{{ errorMsg }}</p>
        <button class="btn-generate" @click="phase = 'idle'">重新生成</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import axios from 'axios'

const BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5001'

const route = useRoute()
const router = useRouter()

const simulationId = computed(() => route.query.simulationId || '')
const graphId      = computed(() => route.query.graphId      || '')
const caseName     = computed(() => route.query.caseName     || '')

const phase        = ref('idle')
const progressPct  = ref(0)
const logLines     = ref([])
const errorMsg     = ref('')
const reportMarkdown = ref('')
const verdictData  = ref(null)
const generatedAt  = ref('')
const markdownRef          = ref(null)
const reportMainRef         = ref(null)
const tocItems              = ref([])
const activeTocId           = ref('__dashboard')
const isReportBodyCollapsed = ref(false)
const isDashboardCollapsed  = ref(false)

let pollTimer    = null
let tocObserver  = null

// ── 计算属性 ──────────────────────────────────────────
const statusDotClass = computed(() => ({
  idle: 'dot-idle', generating: 'dot-running', done: 'dot-done', error: 'dot-error',
}[phase.value]))

const statusLabel = computed(() => ({
  idle: '等待生成', generating: '生成中...', done: '已完成', error: '生成失败',
}[phase.value]))

const plaintiffPct  = computed(() => {
  const p = verdictData.value?.plaintiff_win_probability
  if (p == null) return 50
  // 兼容 0-1 和 0-100 两种格式
  return Math.round(Math.min(100, Math.max(0, p > 1 ? p : p * 100)))
})
const defendantPct  = computed(() => 100 - plaintiffPct.value)

const caseTypeText  = computed(() => {
  const t = verdictData.value?.verdict_type || ''
  if (t.includes('criminal')) return '刑事案件'
  if (t.includes('administrative')) return '行政案件'
  return '民事案件'
})
const plaintiffLabel = computed(() =>
  verdictData.value?.verdict_type?.startsWith('criminal') ? '公诉方' : '原告方'
)
const defendantLabel = computed(() =>
  verdictData.value?.verdict_type?.startsWith('criminal') ? '辩护方' : '被告方'
)
const confidenceText = computed(() => ({
  high: '高', medium: '中', low: '低',
}[verdictData.value?.confidence_level || 'low'] || '低'))

// ── Markdown 渲染（修复版）────────────────────────────
const renderedMarkdown = computed(() => {
  if (!reportMarkdown.value) return '<p style="color:#475569;font-style:italic">报告内容为空</p>'
  return renderMd(reportMarkdown.value)
})

function escHtml(s) {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
}

function renderInline(s) {
  return escHtml(s)
    .replace(/\*\*\*(.+?)\*\*\*/g, '<strong><em>$1</em></strong>')
    .replace(/\*\*(.+?)\*\*/g,     '<strong>$1</strong>')
    .replace(/\*(.+?)\*/g,         '<em>$1</em>')
    .replace(/`(.+?)`/g,           '<code class="inline-code">$1</code>')
}

function renderMd(raw) {
  if (!raw || !raw.trim()) return '<p style="color:#475569;font-style:italic">报告内容为空</p>'

  // 先移除末尾 JSON 代码块（结构化数据，不展示在报告正文里）
  let md = raw.replace(/```json[\s\S]*?```/g, '').trim()

  const lines = md.split('\n')
  const out = []
  let i = 0

  while (i < lines.length) {
    const line = lines[i]

    // ── 代码块 ──
    if (line.startsWith('```')) {
      const lang = line.slice(3).trim() || 'text'
      const codeLines = []
      i++
      while (i < lines.length && !lines[i].startsWith('```')) {
        codeLines.push(escHtml(lines[i]))
        i++
      }
      out.push(`<pre class="code-block"><code class="lang-${lang}">${codeLines.join('\n')}</code></pre>`)
      i++
      continue
    }

    // ── 水平线 ──
    if (/^---+$/.test(line.trim()) || /^\*\*\*+$/.test(line.trim())) {
      out.push('<hr class="md-hr" />')
      i++
      continue
    }

    // ── 标题 ──
    const h1 = line.match(/^# (.+)$/)
    const h2 = line.match(/^## (.+)$/)
    const h3 = line.match(/^### (.+)$/)
    const h4 = line.match(/^#### (.+)$/)
    if (h1) {
      const id = 'toc-' + h1[1].trim().replace(/\s+/g, '-').replace(/[^\w\u4e00-\u9fa5-]/g, '')
      out.push(`<h1 id="${id}" class="md-h1">${renderInline(h1[1])}</h1>`)
      i++; continue
    }
    if (h2) {
      const id = 'toc-' + h2[1].trim().replace(/\s+/g, '-').replace(/[^\w\u4e00-\u9fa5-]/g, '')
      out.push(`<h2 id="${id}" class="md-h2">${renderInline(h2[1])}</h2>`)
      i++; continue
    }
    if (h3) {
      out.push(`<h3 class="md-h3">${renderInline(h3[1])}</h3>`)
      i++; continue
    }
    if (h4) {
      out.push(`<h4 class="md-h4">${renderInline(h4[1])}</h4>`)
      i++; continue
    }

    // ── 引用块（块引用） ──
    if (line.startsWith('> ') || line === '>') {
      const bqLines = []
      while (i < lines.length && (lines[i].startsWith('> ') || lines[i] === '>')) {
        bqLines.push(renderInline(lines[i].replace(/^>\s?/, '')))
        i++
      }
      out.push(`<blockquote class="md-blockquote">${bqLines.join('<br>')}</blockquote>`)
      continue
    }

    // ── 无序列表 ──
    if (/^[*\-+] /.test(line)) {
      const ulLines = []
      while (i < lines.length && /^[*\-+] /.test(lines[i])) {
        ulLines.push(`<li>${renderInline(lines[i].replace(/^[*\-+] /, ''))}</li>`)
        i++
      }
      out.push(`<ul class="md-ul">${ulLines.join('')}</ul>`)
      continue
    }

    // ── 有序列表 ──
    if (/^\d+\. /.test(line)) {
      const olLines = []
      while (i < lines.length && /^\d+\. /.test(lines[i])) {
        olLines.push(`<li>${renderInline(lines[i].replace(/^\d+\. /, ''))}</li>`)
        i++
      }
      out.push(`<ol class="md-ol">${olLines.join('')}</ol>`)
      continue
    }

    // ── 空行 ──
    if (line.trim() === '') {
      i++
      continue
    }

    // ── 普通段落 ──
    const paraLines = []
    while (i < lines.length && lines[i].trim() !== '' && !lines[i].startsWith('#') && !lines[i].startsWith('> ') && !lines[i].startsWith('```') && !/^[*\-+] /.test(lines[i]) && !/^\d+\. /.test(lines[i]) && !/^---+$/.test(lines[i].trim())) {
      paraLines.push(renderInline(lines[i]))
      i++
    }
    if (paraLines.length) {
      out.push(`<p class="md-p">${paraLines.join('<br>')}</p>`)
    }
  }
  return out.join('\n')
}

// ── 目录生成 ──────────────────────────────────────────
function buildToc(md) {
  const items = []
  for (const line of md.split('\n')) {
    const m1 = line.match(/^# (.+)$/)
    const m2 = line.match(/^## (.+)$/)
    if (m1 || m2) {
      const text = (m1 || m2)[1].trim()
      const level = m1 ? 1 : 2
      const id = 'toc-' + text.replace(/\s+/g, '-').replace(/[^\w\u4e00-\u9fa5-]/g, '')
      items.push({ text, level, id })
    }
  }
  tocItems.value = items
}

function scrollToSection(id) {
  activeTocId.value = id
  if (id === '__dashboard') {
    reportMainRef.value?.scrollTo({ top: 0, behavior: 'smooth' })
    return
  }
  const el = document.getElementById(id)
  if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

function setupTocObserver() {
  if (tocObserver) tocObserver.disconnect()
  tocObserver = new IntersectionObserver(
    entries => {
      for (const e of entries) {
        if (e.isIntersecting) { activeTocId.value = e.target.id; break }
      }
    },
    { threshold: 0.2 }
  )
  nextTick(() => {
    const hs = markdownRef.value?.querySelectorAll('h1[id], h2[id]')
    hs?.forEach(h => tocObserver.observe(h))
  })
}

// ── 生成流程 ──────────────────────────────────────────
async function startGenerate() {
  phase.value      = 'generating'
  progressPct.value = 5
  logLines.value   = ['正在启动报告生成任务...']

  try {
    const res = await axios.post(`${BASE_URL}/api/lexsim/verdict/generate`, {
      simulation_id: simulationId.value,
      graph_id:      graphId.value,
      case_name:     caseName.value,
    })
    const data = res.data?.data || {}
    console.log('Generate response:', data)
    // 后端直接返回已有报告（不需要重新生成）
    if (data.existing && data.report_id) {
      logLines.value.push('已找到现有报告，正在加载...')
      progressPct.value = 100
      await loadReport(data.report_id)
      return
    }
    const taskId = data.task_id
    if (!taskId) throw new Error('未获取到任务 ID')
    logLines.value.push(`任务已创建: ${taskId}`)
    pollTimer = setInterval(() => pollTask(taskId), 3000)
  } catch (err) {
    console.error('Generate error:', err)
    errorMsg.value = err.response?.data?.error || err.message
    phase.value = 'error'
  }
}

async function pollTask(taskId) {
  try {
    const res  = await axios.get(`${BASE_URL}/api/lexsim/verdict/generate/status/${taskId}`)
    const data = res.data?.data || {}

    if (data.progress != null) progressPct.value = Math.min(95, Math.round(Number(data.progress)))
    if (data.message)          logLines.value.push(data.message)

    if (data.status === 'completed') {
      clearInterval(pollTimer); pollTimer = null
      progressPct.value = 100
      await loadReport(data.result?.report_id)
    } else if (data.status === 'failed') {
      clearInterval(pollTimer); pollTimer = null
      errorMsg.value = data.message || '报告生成失败'
      phase.value = 'error'
    }
  } catch (err) {
    logLines.value.push(`轮询异常: ${err.message}`)
  }
}

async function loadReport(rid) {
  try {
    const res  = await axios.get(`${BASE_URL}/api/lexsim/verdict/${rid}`)
    reportMarkdown.value = res.data?.data?.markdown_content || ''
    console.log('Report Markdown:', reportMarkdown.value.substring(0, 200))

    try {
      const sRes = await axios.get(`${BASE_URL}/api/lexsim/verdict/${rid}/structured`)
      verdictData.value = sRes.data?.data || null
      console.log('Verdict Data:', verdictData.value)
    } catch (err) {
      console.error('Structured data error:', err)
      verdictData.value = null
    }

    generatedAt.value = new Date().toLocaleString('zh-CN', { hour12: false })
    phase.value = 'done'
    buildToc(reportMarkdown.value)
    setupTocObserver()
  } catch (err) {
    errorMsg.value = err.response?.data?.error || err.message
    phase.value = 'error'
  }
}

function fmtAmount(val) {
  if (!val && val !== 0) return '—'
  return '¥ ' + Number(val).toLocaleString('zh-CN')
}

function copyReport() {
  navigator.clipboard?.writeText(reportMarkdown.value)
    .then(() => alert('已复制到剪贴板'))
    .catch(() => alert('复制失败，请手动选择文本'))
}

// ── 页面挂载：自动检查已有报告 ───────────────────────────
onMounted(async () => {
  if (!simulationId.value) { phase.value = 'idle'; return }
  phase.value = 'checking'
  try {
    const res = await axios.get(`${BASE_URL}/api/lexsim/verdict/by-simulation/${simulationId.value}`)
    const report = res.data?.data
    if (report && report.report_id) {
      await loadReport(report.report_id)
    } else {
      phase.value = 'idle'
    }
  } catch {
    phase.value = 'idle'
  }
})

// ── 重新执行确认 ───────────────────────────────────────
function confirmRerun() {
  if (!confirm('确定要重新生成判决预测报告吗？将覆盖现有报告。')) return
  if (tocObserver) { tocObserver.disconnect(); tocObserver = null }
  phase.value = 'idle'
  reportMarkdown.value = ''
  verdictData.value = null
  tocItems.value = []
  generatedAt.value = ''
  progressPct.value = 0
  logLines.value = []
  errorMsg.value = ''
  isReportBodyCollapsed.value = false
  isDashboardCollapsed.value = false
  startGenerate()
}

onUnmounted(() => {
  if (pollTimer)   clearInterval(pollTimer)
  if (tocObserver) tocObserver.disconnect()
})
</script>

<style scoped>
/* ═══════════ 基础布局 ═══════════ */
.verdict-view {
  min-height: 100vh;
  height: 100vh;
  background: #070d14;
  color: #e2e8f0;
  font-family: 'Inter', 'PingFang SC', 'Noto Serif SC', sans-serif;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

/* Header */
.verdict-header {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 12px 24px;
  background: #0f1923;
  border-bottom: 1px solid #1e3a5f;
  flex-shrink: 0;
}
.btn-back {
  background: transparent;
  border: 1px solid #1e3a5f;
  color: #64748b;
  border-radius: 6px;
  padding: 5px 12px;
  font-size: 12px;
  cursor: pointer;
  white-space: nowrap;
}
.btn-back:hover { color: #93c5fd; border-color: #2563eb; }
.header-title { display: flex; align-items: center; gap: 10px; flex: 1; }
.header-icon  { font-size: 22px; }
.header-h1    { margin: 0; font-size: 15px; font-weight: 700; color: #f8fafc; }
.header-sub   { font-size: 11px; color: #475569; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 500px; }
.header-right { display: flex; align-items: center; gap: 10px; flex-shrink: 0; }
.status-dot { width: 8px; height: 8px; border-radius: 50%; }
.dot-idle    { background: #475569; }
.dot-running { background: #22c55e; box-shadow: 0 0 6px #22c55e; animation: blink 1.2s infinite; }
.dot-done    { background: #3b82f6; }
.dot-error   { background: #ef4444; }
@keyframes blink { 0%,100%{opacity:1} 50%{opacity:.3} }
.status-label { font-size: 12px; color: #94a3b8; }
.btn-export {
  background: #1e3a5f;
  border: 1px solid #2563eb;
  color: #93c5fd;
  border-radius: 5px;
  padding: 4px 12px;
  font-size: 11px;
  cursor: pointer;
}
.btn-export:hover { background: #1d4ed8; color: #fff; }
.btn-rerun {
  background: #431407;
  border: 1px solid #ea580c;
  color: #fb923c;
  border-radius: 5px;
  padding: 4px 12px;
  font-size: 11px;
  cursor: pointer;
}
.btn-rerun:hover { background: #ea580c; color: #fff; }

/* 居中区（生成中/空闲/错误） */
.center-area {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 40px 24px;
}
.gen-card, .idle-card {
  background: #0f1923;
  border: 1px solid #1e3a5f;
  border-radius: 16px;
  padding: 40px 48px;
  text-align: center;
  max-width: 540px;
  width: 100%;
}
.idle-icon { font-size: 48px; margin-bottom: 16px; }
.gen-card h2, .idle-card h2 { margin: 0 0 12px; font-size: 19px; color: #f1f5f9; }
.gen-hint, .idle-card p { color: #64748b; font-size: 13px; line-height: 1.6; margin-bottom: 20px; }
.btn-generate {
  background: #2563eb; border: none; color: #fff;
  border-radius: 8px; padding: 10px 28px; font-size: 14px;
  font-weight: 600; cursor: pointer; transition: background 0.2s;
}
.btn-generate:hover { background: #1d4ed8; }
.spinner {
  width: 40px; height: 40px; border: 3px solid #1e3a5f;
  border-top-color: #3b82f6; border-radius: 50%;
  animation: spin 0.8s linear infinite; margin: 0 auto 20px;
}
@keyframes spin { to { transform: rotate(360deg); } }
.progress-track { height: 6px; background: #1e3a5f; border-radius: 3px; margin: 16px 0 6px; overflow: hidden; }
.progress-fill  { height: 100%; background: linear-gradient(90deg, #1d4ed8, #3b82f6); border-radius: 3px; transition: width 0.5s; }
.progress-text  { font-size: 12px; color: #64748b; }
.gen-logs { margin-top: 16px; text-align: left; background: #070d14; border-radius: 6px; padding: 10px 12px; max-height: 130px; overflow-y: auto; }
.log-line { font-size: 11px; color: #475569; font-family: monospace; line-height: 1.8; }

/* ═══════════ 报告双栏布局 ═══════════ */
.report-area {
  flex: 1;
  display: flex;
  overflow: hidden;
  min-height: 0;
}

/* 左侧目录 */
.report-toc {
  width: 200px;
  flex-shrink: 0;
  background: #0a1520;
  border-right: 1px solid #1e3a5f;
  padding: 16px 0;
  overflow-y: auto;
  z-index: 1;
}
.report-toc::-webkit-scrollbar { width: 3px; }
.report-toc::-webkit-scrollbar-thumb { background: #1e3a5f; }
.toc-title { font-size: 10px; font-weight: 700; color: #334155; text-transform: uppercase; letter-spacing: 0.08em; padding: 0 14px 8px; border-bottom: 1px solid #1a2f45; margin-bottom: 6px; }
.toc-list { list-style: none; margin: 0; padding: 0; }
.toc-item a {
  display: block; padding: 5px 14px; font-size: 12px; color: #475569;
  text-decoration: none; line-height: 1.4; transition: all 0.12s;
  border-left: 2px solid transparent;
}
.toc-item a:hover { color: #93c5fd; background: rgba(37,99,235,0.05); }
.toc-level-2 a { padding-left: 24px; font-size: 11px; }
.toc-item.active a { color: #60a5fa; border-left-color: #2563eb; background: rgba(37,99,235,0.08); }

/* 右侧主内容 */
.report-main {
  flex: 1;
  min-width: 0;
  overflow-y: auto;
  padding: 20px 24px 40px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}
.report-main::-webkit-scrollbar { width: 5px; }
.report-main::-webkit-scrollbar-thumb { background: #1e3a5f; border-radius: 3px; }

/* ═══════════ 判决预测仪表盘 ═══════════ */
.dashboard {
  background: #0d1e30;
  border: 1px solid #1e3a5f;
  border-radius: 14px;
  overflow: hidden;
  position: relative;
  z-index: 10;
  flex-shrink: 0;
}

/* Dashboard 折叠 Header */
.dashboard-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  background: #0a1520;
  border-bottom: 1px solid #1e3a5f;
  cursor: pointer;
  user-select: none;
  transition: background 0.15s;
}
.dashboard-header:hover { background: #0d1e2e; }
.dh-title { font-size: 12px; font-weight: 600; color: #64748b; flex: 1; text-transform: uppercase; letter-spacing: 0.06em; }

/* 案件信息条 */
.case-info-bar {
  display: flex;
  align-items: center;
  gap: 0;
  padding: 10px 20px;
  background: #0a1520;
  border-bottom: 1px solid #1e3a5f;
  flex-wrap: wrap;
  gap: 12px;
}
.ci-item  { display: flex; align-items: center; gap: 6px; min-width: 0; }
.ci-label { font-size: 10px; color: #334155; white-space: nowrap; flex-shrink: 0; }
.ci-val   { font-size: 12px; color: #94a3b8; font-weight: 500; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 320px; }
.ci-sep   { width: 1px; height: 14px; background: #1e3a5f; flex-shrink: 0; }
.conf-badge { padding: 1px 8px; border-radius: 10px; border: 1px solid; font-size: 11px; }
.conf-high   { color: #4ade80; border-color: #4ade80; background: rgba(74,222,128,.1); }
.conf-medium { color: #f59e0b; border-color: #f59e0b; background: rgba(245,158,11,.1); }
.conf-low    { color: #f87171; border-color: #f87171; background: rgba(248,113,113,.1); }

/* 胜诉概率区 */
.prob-section {
  display: flex;
  align-items: center;
  gap: 20px;
  padding: 20px 24px;
}
.prob-side { min-width: 70px; }
.prob-plaintiff { text-align: left; }
.prob-defendant { text-align: right; }
.prob-role { font-size: 12px; color: #64748b; margin-bottom: 2px; }
.prob-pct  { font-size: 32px; font-weight: 800; line-height: 1; }
.prob-desc { font-size: 10px; color: #334155; margin-top: 2px; }

.prob-bar-wrap { flex: 1; }
.prob-bar-track {
  height: 20px;
  background: #0a1520;
  border-radius: 10px;
  position: relative;
  overflow: hidden;
  border: 1px solid #1e3a5f;
}
.prob-fill { position: absolute; top: 0; height: 100%; transition: width 1s cubic-bezier(0.4,0,0.2,1); }
.prob-fill-p { left: 0;  background: linear-gradient(90deg, #1d4ed8, #3b82f6); border-radius: 10px 0 0 10px; }
.prob-fill-d { right: 0; background: linear-gradient(270deg, #991b1b, #ef4444); border-radius: 0 10px 10px 0; }
.prob-mid-line { position: absolute; left: 50%; top: 0; width: 2px; height: 100%; background: #1e3a5f; transform: translateX(-50%); z-index: 1; }
.prob-bar-labels {
  display: flex; justify-content: space-between;
  font-size: 10px; color: #334155; margin-top: 4px; padding: 0 2px;
}

/* 三栏详情 */
.detail-grid {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 1px;
  background: #1e3a5f;
  border-top: 1px solid #1e3a5f;
}
.detail-card {
  background: #0d1e30;
  padding: 16px 18px;
}
.detail-card-title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  font-weight: 700;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 12px;
}
.dct-icon { font-size: 13px; font-style: normal; }
.dct-blue   { color: #3b82f6; }
.dct-green  { color: #22c55e; }
.dct-orange { color: #f59e0b; }
.detail-empty {
  font-size: 12px;
  color: #334155;
  font-style: italic;
  display: flex;
  align-items: center;
  gap: 6px;
}
.empty-icon {
  font-size: 16px;
  color: #475569;
  opacity: 0.6;
}

/* 关键因素 */
.factor-list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 8px; }
.factor-item { display: flex; gap: 8px; align-items: flex-start; }
.fi-num {
  flex-shrink: 0; width: 18px; height: 18px;
  background: rgba(59,130,246,.15); border: 1px solid rgba(59,130,246,.3);
  border-radius: 4px; font-size: 10px; color: #60a5fa; font-weight: 700;
  display: flex; align-items: center; justify-content: center; margin-top: 1px;
}
.fi-text { font-size: 12px; color: #cbd5e1; line-height: 1.5; }

/* 赔偿区间 */
.comp-display { }
.comp-range {
  display: flex; align-items: baseline; gap: 5px; margin-bottom: 6px; flex-wrap: wrap;
}
.comp-num  { font-size: 16px; font-weight: 700; color: #22c55e; }
.comp-wave { font-size: 14px; color: #475569; }
.comp-cny  { font-size: 10px; color: #475569; }
.comp-note { font-size: 11px; color: #64748b; margin-bottom: 8px; }
.comp-bar-wrap { height: 4px; background: #0a1520; border-radius: 2px; overflow: hidden; }
.comp-bar { height: 100%; width: 70%; background: linear-gradient(90deg, #16a34a, #22c55e); border-radius: 2px; }

/* 法律风险 */
.risk-list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 8px; }
.risk-item { display: flex; gap: 8px; align-items: flex-start; }
.ri-dot {
  flex-shrink: 0; width: 6px; height: 6px; border-radius: 50%;
  background: #f59e0b; margin-top: 5px;
}
.ri-text { font-size: 12px; color: #94a3b8; line-height: 1.5; }

/* 免责声明 — 紧跟在 dashboard 下方，始终可见 */
.disclaimer {
  padding: 10px 20px;
  background: rgba(245,158,11,0.04);
  border: 1px solid rgba(245,158,11,0.15);
  border-radius: 10px;
  font-size: 11px;
  color: #57534e;
  line-height: 1.6;
  flex-shrink: 0;
}

/* ═══════════ 报告正文 — 独立滚动区，占满剩余空间 ═══════════ */
.report-body {
  background: #0d1e30;
  border: 1px solid #1e3a5f;
  border-radius: 14px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
  transition: max-height 0.3s ease;
  max-height: 9999px;
}
.report-body.collapsed {
  max-height: 52px;   /* 仅 header 高度 */
  overflow: hidden;
}
.report-body-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 20px;
  background: #0a1520;
  border-bottom: 1px solid #1e3a5f;
  flex-shrink: 0;
  cursor: pointer;
  user-select: none;
}
.report-body-header:hover { background: #0d1e2e; }
.rbh-icon  { font-size: 14px; }
.rbh-title { font-size: 13px; font-weight: 600; color: #94a3b8; flex: 1; }
.rbh-hint  { font-size: 11px; color: #334155; margin-right: 8px; }
.rbh-toggle { font-size: 11px; color: #475569; padding: 2px 8px; border-radius: 4px; background: #1e3a5f; transition: all 0.15s; }
.report-body-header:hover .rbh-toggle { color: #93c5fd; background: #2563eb; }
.rbh-chevron { font-size: 12px; color: #475569; transition: transform 0.25s ease; }
.rbh-chevron.open { transform: rotate(180deg); }

/* Markdown 正文样式 — 自己的滚动条 */
.markdown-content {
  padding: 24px 28px;
  font-size: 14px;
  line-height: 1.85;
  color: #b0bec5;
  overflow-y: auto;
  flex: 1;
}
.markdown-content::-webkit-scrollbar { width: 4px; }
.markdown-content::-webkit-scrollbar-thumb { background: #1e3a5f; border-radius: 2px; }

/* 标题 */
.markdown-content :deep(.md-h1) {
  font-size: 20px; font-weight: 700; color: #f1f5f9;
  margin: 28px 0 12px; padding-bottom: 8px;
  border-bottom: 2px solid #1e3a5f;
  scroll-margin-top: 16px;
}
.markdown-content :deep(.md-h2) {
  font-size: 16px; font-weight: 700; color: #e2e8f0;
  margin: 24px 0 10px; padding-bottom: 6px;
  border-bottom: 1px solid #1a2f45;
  scroll-margin-top: 16px;
}
.markdown-content :deep(.md-h3) {
  font-size: 14px; font-weight: 700; color: #cbd5e1;
  margin: 18px 0 8px;
}
.markdown-content :deep(.md-h4) {
  font-size: 13px; font-weight: 600; color: #94a3b8;
  margin: 14px 0 6px;
}

/* 段落 */
.markdown-content :deep(.md-p) {
  margin: 0 0 14px; color: #b0bec5; line-height: 1.85;
}
.markdown-content :deep(strong) { color: #e2e8f0; font-weight: 600; }
.markdown-content :deep(em) { color: #94a3b8; font-style: italic; }

/* 引用块 */
.markdown-content :deep(.md-blockquote) {
  border-left: 3px solid #2563eb;
  background: rgba(37,99,235,0.07);
  margin: 14px 0;
  padding: 10px 16px;
  border-radius: 0 6px 6px 0;
  color: #93c5fd;
  font-style: italic;
  font-size: 13px;
  line-height: 1.7;
}

/* 列表 */
.markdown-content :deep(.md-ul),
.markdown-content :deep(.md-ol) {
  padding-left: 22px; margin: 10px 0 14px;
}
.markdown-content :deep(.md-ul li),
.markdown-content :deep(.md-ol li) {
  margin-bottom: 6px; color: #b0bec5; line-height: 1.7;
}
.markdown-content :deep(.md-ul li::marker) { color: #2563eb; }
.markdown-content :deep(.md-ol li::marker) { color: #3b82f6; font-weight: 600; }

/* 水平线 */
.markdown-content :deep(.md-hr) {
  border: none; border-top: 1px solid #1e3a5f; margin: 20px 0;
}

/* 代码 */
.markdown-content :deep(.inline-code) {
  background: #0a1520; border: 1px solid #1e3a5f;
  border-radius: 3px; padding: 1px 5px;
  font-family: monospace; font-size: 12px; color: #7dd3fc;
}
.markdown-content :deep(.code-block) {
  background: #060e18; border: 1px solid #1e3a5f;
  border-radius: 8px; padding: 14px 18px; margin: 14px 0;
  overflow-x: auto;
}
.markdown-content :deep(.code-block code) {
  font-family: monospace; font-size: 12px; color: #7dd3fc; line-height: 1.6;
}
</style>
