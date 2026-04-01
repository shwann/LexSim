<template>
  <div class="home-view">
    <!-- ===== 粒子背景 ===== -->
    <canvas ref="bgCanvas" class="bg-canvas" />

    <!-- ===== HERO ===== -->
    <section class="hero">
      <div class="hero-content">
        <div class="hero-badge">
          <span class="badge-dot" />
          AI 驱动 · 法律庭审模拟平台
        </div>

        <div class="hero-logo">
          <!-- 天平 SVG 动画 -->
          <svg viewBox="0 0 200 180" class="scales-svg" xmlns="http://www.w3.org/2000/svg">
            <!-- 顶部圆 -->
            <circle cx="100" cy="18" r="7" fill="none" stroke="#3b82f6" stroke-width="2" />
            <!-- 中柱 -->
            <line x1="100" y1="25" x2="100" y2="110" stroke="#3b82f6" stroke-width="2.5" stroke-linecap="round"/>
            <!-- 底座 -->
            <rect x="72" y="110" width="56" height="8" rx="4" fill="#1e3a5f"/>
            <rect x="60" y="118" width="80" height="5" rx="2.5" fill="#1e3a5f"/>
            <!-- 横梁（摇摆动画） -->
            <g class="beam-group">
              <line class="beam" x1="30" y1="55" x2="170" y2="55" stroke="#60a5fa" stroke-width="2.5" stroke-linecap="round"/>
              <!-- 左挂绳 -->
              <line x1="30" y1="55" x2="25" y2="85" stroke="#60a5fa" stroke-width="1.5" stroke-dasharray="4 2"/>
              <line x1="30" y1="55" x2="35" y2="85" stroke="#60a5fa" stroke-width="1.5" stroke-dasharray="4 2"/>
              <!-- 右挂绳 -->
              <line x1="170" y1="55" x2="165" y2="85" stroke="#60a5fa" stroke-width="1.5" stroke-dasharray="4 2"/>
              <line x1="170" y1="55" x2="175" y2="85" stroke="#60a5fa" stroke-width="1.5" stroke-dasharray="4 2"/>
              <!-- 左托盘 -->
              <ellipse cx="30" cy="88" rx="18" ry="5" fill="#0f1923" stroke="#60a5fa" stroke-width="1.5"/>
              <!-- 右托盘 -->
              <ellipse cx="170" cy="88" rx="18" ry="5" fill="#0f1923" stroke="#60a5fa" stroke-width="1.5"/>
              <!-- 光晕 -->
              <ellipse cx="30" cy="88" rx="18" ry="5" fill="#3b82f620" />
              <ellipse cx="170" cy="88" rx="18" ry="5" fill="#3b82f620" />
            </g>
            <!-- 中心挂点 -->
            <circle cx="100" cy="55" r="5" fill="#3b82f6"/>
            <!-- 装饰星点 -->
            <circle cx="55" cy="40" r="2" fill="#60a5fa" opacity="0.6" class="star-1"/>
            <circle cx="145" cy="35" r="1.5" fill="#60a5fa" opacity="0.5" class="star-2"/>
            <circle cx="165" cy="60" r="1.5" fill="#a78bfa" opacity="0.6" class="star-3"/>
          </svg>
        </div>

        <h1 class="hero-title">
          <span class="title-lex">Lex</span><span class="title-sim">Sim</span>
        </h1>
        <p class="hero-sub">法律庭审智能模拟平台</p>
        <p class="hero-desc">
          基于大语言模型与多智能体协作，还原真实庭审场景。<br />
          从案件材料到宣判结果，全程 AI 驱动，助力法律研究与实践培训。
        </p>

        <div class="hero-actions">
          <button class="btn-primary" @click="$router.push('/lexsim/create')">
            <svg viewBox="0 0 20 20" class="btn-icon" fill="currentColor">
              <path d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z"/>
            </svg>
            开始新案件
          </button>
          <button class="btn-ghost" @click="scrollTo('features')">了解更多</button>
        </div>

        <div class="hero-stats">
          <div class="stat-item">
            <span class="stat-num">{{ stats.projects }}</span>
            <span class="stat-label">历史案件</span>
          </div>
          <div class="stat-divider" />
          <div class="stat-item">
            <span class="stat-num">{{ stats.simulations }}</span>
            <span class="stat-label">庭审模拟</span>
          </div>
          <div class="stat-divider" />
          <div class="stat-item">
            <span class="stat-num">13</span>
            <span class="stat-label">庭审轮次</span>
          </div>
          <div class="stat-divider" />
          <div class="stat-item">
            <span class="stat-num">10+</span>
            <span class="stat-label">法庭角色</span>
          </div>
        </div>
      </div>

      <!-- 右侧装饰面板 -->
      <div class="hero-visual">
        <div class="visual-card card-main">
          <div class="vc-header">
            <span class="vc-dot green"/><span class="vc-dot yellow"/><span class="vc-dot red"/>
            <span class="vc-title">庭审进行中</span>
          </div>
          <div class="vc-roles">
            <div v-for="role in demoRoles" :key="role.id" class="role-pill" :style="{ '--rc': role.color }">
              <span class="role-avatar">{{ role.icon }}</span>
              <span>{{ role.name }}</span>
              <span class="role-status" :class="role.active ? 'pulse' : ''">{{ role.active ? '发言中' : '待机' }}</span>
            </div>
          </div>
          <div class="vc-speech">
            <div class="speech-line">
              <span class="sl-role" style="color:#f59e0b">法官</span>
              <span class="sl-text">现在开庭，传唤原告出庭陈述...</span>
            </div>
            <div class="speech-line mt">
              <span class="sl-role" style="color:#3b82f6">原告律师</span>
              <span class="sl-text">根据《合同法》第107条，被告应承担...</span>
            </div>
          </div>
          <div class="vc-progress">
            <span class="vcp-label">庭审进度</span>
            <div class="vcp-bar"><div class="vcp-fill" style="width: 46%" /></div>
            <span class="vcp-pct">R6 / R13</span>
          </div>
        </div>

        <div class="visual-card card-sub card-sub1">
          <div class="sub-icon">📊</div>
          <div class="sub-info">
            <div class="sub-title">判决预测</div>
            <div class="sub-val">原告胜诉 <b>72%</b></div>
          </div>
        </div>
        <div class="visual-card card-sub card-sub2">
          <div class="sub-icon">🧠</div>
          <div class="sub-info">
            <div class="sub-title">AI 智能体</div>
            <div class="sub-val">已部署 <b>8</b> 个</div>
          </div>
        </div>
      </div>
    </section>

    <!-- ===== 特性介绍 ===== -->
    <section class="features-section" id="features">
      <div class="section-header">
        <div class="section-badge">核心能力</div>
        <h2 class="section-title">全流程 AI 法律庭审模拟</h2>
        <p class="section-desc">覆盖庭审全阶段，每个角色均由独立 AI 智能体驱动，真实还原庭审博弈过程</p>
      </div>

      <div class="features-grid">
        <div v-for="feat in features" :key="feat.id" class="feat-card" :style="{ '--accent': feat.color }">
          <div class="feat-icon-wrap">
            <div class="feat-icon">{{ feat.icon }}</div>
            <div class="feat-glow" />
          </div>
          <h3 class="feat-title">{{ feat.title }}</h3>
          <p class="feat-desc">{{ feat.desc }}</p>
          <div class="feat-tags">
            <span v-for="t in feat.tags" :key="t" class="feat-tag">{{ t }}</span>
          </div>
        </div>
      </div>
    </section>

    <!-- ===== 工作流程 ===== -->
    <section class="workflow-section">
      <div class="section-header">
        <div class="section-badge">工作流程</div>
        <h2 class="section-title">四步完成庭审模拟</h2>
      </div>
      <div class="workflow-steps">
        <div v-for="(step, i) in workflowSteps" :key="i" class="ws-item">
          <div class="ws-line" v-if="i < workflowSteps.length - 1" />
          <div class="ws-circle" :style="{ '--sc': step.color }">
            <span>{{ step.num }}</span>
          </div>
          <div class="ws-content">
            <div class="ws-icon">{{ step.icon }}</div>
            <h4 class="ws-title">{{ step.title }}</h4>
            <p class="ws-desc">{{ step.desc }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- ===== 历史案件 ===== -->
    <section class="history-section">
      <div class="section-header">
        <div class="section-badge">历史记录</div>
        <h2 class="section-title">近期庭审模拟</h2>
        <p class="section-desc">点击案件卡片进入详情或继续推进庭审</p>
      </div>

      <!-- 加载中 -->
      <div v-if="loading" class="loading-state">
        <div class="loading-spinner" />
        <span>加载中...</span>
      </div>

      <!-- 空状态 -->
      <div v-else-if="projects.length === 0" class="empty-state">
        <div class="empty-icon">⚖️</div>
        <h3>暂无历史案件</h3>
        <p>开始您的第一个法律庭审模拟</p>
        <button class="btn-primary sm" @click="$router.push('/lexsim/create')">立即创建</button>
      </div>

      <!-- 案件卡片列表 -->
      <div v-else class="history-grid">
        <div
          v-for="proj in projects"
          :key="proj.project_id"
          class="hist-card"
          :class="'status-' + proj.status"
          @click="handleProjectClick(proj)"
        >
          <!-- 卡片头部 -->
          <div class="hc-header">
            <div class="hc-type-badge" :class="proj.case_type">
              {{ proj.case_type === 'criminal' ? '刑事' : proj.case_type === 'civil' ? '民事' : '通用' }}
            </div>
            <div class="hc-status-dot" :class="proj.status" :title="STATUS_LABELS[proj.status]" />
          </div>

          <!-- 案件名称 -->
          <h3 class="hc-name">{{ proj.name }}</h3>

          <!-- 元信息 -->
          <div class="hc-meta">
            <div class="hc-meta-row">
              <svg class="meta-icon" viewBox="0 0 16 16" fill="currentColor">
                <path d="M8 1a7 7 0 100 14A7 7 0 008 1zm.75 4a.75.75 0 00-1.5 0v3.25L5.22 9.78a.75.75 0 001.06 1.06l2-2A.75.75 0 008.75 8.25V5z"/>
              </svg>
              <span>{{ formatDate(proj.created_at) }}</span>
            </div>
            <div class="hc-meta-row" v-if="proj.files && proj.files.length">
              <svg class="meta-icon" viewBox="0 0 16 16" fill="currentColor">
                <path d="M3 2a1 1 0 011-1h5.586a1 1 0 01.707.293l3.414 3.414A1 1 0 0114 5.414V14a1 1 0 01-1 1H4a1 1 0 01-1-1V2z"/>
              </svg>
              <span>{{ proj.files.length }} 份材料</span>
            </div>
          </div>

          <!-- 状态文字 -->
          <div class="hc-status-label">
            <span class="hc-sl-dot" :class="proj.status" />
            {{ STATUS_LABELS[proj.status] || proj.status }}
          </div>

          <!-- 操作按钮 -->
          <div class="hc-actions">
            <button
              class="hc-btn primary"
              @click.stop="handleProjectAction(proj)"
            >
              {{ getActionLabel(proj) }}
            </button>
          </div>

          <!-- 装饰线 -->
          <div class="hc-deco-line" />
        </div>

        <!-- 新建卡片 -->
        <div class="hist-card new-card" @click="$router.push('/lexsim/create')">
          <div class="new-card-inner">
            <div class="new-icon">+</div>
            <h3>新建案件</h3>
            <p>创建新的法律庭审模拟</p>
          </div>
        </div>
      </div>

      <!-- 更多历史记录 -->
      <div v-if="allProjects.length > 10" class="history-more">
        <button class="btn-more" @click="toggleShowAll">
          {{ showAll ? '收起' : `查看更多历史记录（共 ${allProjects.length} 条）` }}
        </button>
      </div>
    </section>

    <!-- ===== 底部 ===== -->
    <footer class="home-footer">
      <div class="footer-logo">
        <span class="title-lex">Lex</span><span class="title-sim">Sim</span>
      </div>
      <p class="footer-desc">AI 驱动的法律庭审智能模拟平台 · 仅供研究与教育用途</p>
    </footer>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api/index.js'

const router = useRouter()
const bgCanvas = ref(null)
let animFrame = null
let particles = []

const loading = ref(true)
const projects = ref([])
const allProjects = ref([])
const showAll = ref(false)
const stats = ref({ projects: 0, simulations: 0 })

// ---- 演示角色 ----
const demoRoles = [
  { id: 1, icon: '⚖', name: '法官', color: '#f59e0b', active: true },
  { id: 2, icon: '👔', name: '原告律师', color: '#3b82f6', active: false },
  { id: 3, icon: '🛡', name: '辩护律师', color: '#ef4444', active: false },
  { id: 4, icon: '📋', name: '检察官', color: '#a855f7', active: false },
]

// ---- 状态标签 ----
const STATUS_LABELS = {
  created: '已创建',
  ontology_generated: '本体已生成',
  graph_building: '图谱构建中',
  graph_completed: '图谱已完成',
  processing: '处理中',
  graph_built: '图谱已构建',
  prepared: '准备完成',
  running: '庭审进行中',
  completed: '已完成',
  failed: '失败',
  error: '发生错误',
}

// ---- 特性列表 ----
const features = [
  {
    id: 1, icon: '🧠', color: '#3b82f6',
    title: '多智能体协作',
    desc: '法官、律师、检察官、证人等角色均由独立 AI 智能体扮演，每个智能体拥有独立人设与记忆，模拟真实庭审对抗。',
    tags: ['大语言模型', '角色扮演', '记忆管理'],
  },
  {
    id: 2, icon: '📋', color: '#a855f7',
    title: '法律本体图谱',
    desc: '自动从案件材料中提取实体和关系，构建法律知识图谱，覆盖民事与刑事案件的核心法律要素。',
    tags: ['知识图谱', 'NLP抽取', '民事/刑事'],
  },
  {
    id: 3, icon: '⚖', color: '#f59e0b',
    title: '完整庭审流程',
    desc: '严格遵循庭审程序，从开庭准备到最终宣判，完整覆盖法庭调查、法庭辩论、最后陈述六大阶段共13轮次。',
    tags: ['开庭准备', '法庭调查', '宣判'],
  },
  {
    id: 4, icon: '📊', color: '#10b981',
    title: '实时庭审追踪',
    desc: '实时监控每一轮发言、每一个动作，支持发言视图、完整日志、统计数据三种视角，全面掌握庭审动态。',
    tags: ['实时刷新', '多视图', '统计分析'],
  },
  {
    id: 5, icon: '🔮', color: '#ef4444',
    title: 'AI 判决预测',
    desc: '庭审结束后，基于完整庭审记录生成专业判决预测报告，包含胜诉概率、赔偿区间和法律风险分析。',
    tags: ['判决预测', 'Markdown报告', '风险评估'],
  },
  {
    id: 6, icon: '📁', color: '#22d3ee',
    title: '材料智能解析',
    desc: '支持上传 PDF、TXT、Markdown 格式的案件材料，AI 自动提取关键信息，构建案件事实基础。',
    tags: ['PDF解析', '多格式', '自动提取'],
  },
]

// ---- 工作流程 ----
const workflowSteps = [
  {
    num: '01', icon: '📁', color: '#3b82f6',
    title: '上传案件材料',
    desc: '输入案件名称、类型，上传相关法律文件材料',
  },
  {
    num: '02', icon: '🧬', color: '#a855f7',
    title: '构建知识图谱',
    desc: 'AI 自动提取实体关系，生成法律知识图谱',
  },
  {
    num: '03', icon: '⚙', color: '#f59e0b',
    title: '生成庭审配置',
    desc: '自动生成各角色人设，规划13轮庭审流程',
  },
  {
    num: '04', icon: '🏛', color: '#10b981',
    title: '启动庭审模拟',
    desc: '多智能体协作推进庭审，实时查看判决结果',
  },
]

// ---- 获取项目列表 ----
async function fetchProjects() {
  try {
    const res = await api.get('/api/graph/project/list?limit=100')
    if (res.success) {
      const all = res.data || []
      const lexsimProjects = all.filter(p => p.lexsim_mode === true)
      allProjects.value = lexsimProjects
      projects.value = lexsimProjects.slice(0, 10)
      stats.value.projects = lexsimProjects.length
    }
  } catch (e) {
    console.warn('获取项目列表失败', e)
  } finally {
    loading.value = false
  }
}

function toggleShowAll() {
  showAll.value = !showAll.value
  projects.value = showAll.value ? allProjects.value : allProjects.value.slice(0, 10)
}

async function fetchSimulationCount() {
  try {
    const res = await api.get('/api/simulation/list')
    if (res.success) {
      stats.value.simulations = (res.data || []).length
    }
  } catch (e) {
    // 忽略
  }
}

// ---- 项目操作 ----
function getActionLabel(proj) {
  switch (proj.status) {
    case 'completed': return '查看详情'
    case 'running': return '进入庭审'
    case 'prepared': return '启动庭审'
    case 'graph_completed':
    case 'graph_built': return '继续准备'
    case 'graph_building': return '图谱构建中'
    case 'ontology_generated': return '构建图谱'
    case 'failed':
    case 'error': return '重新创建'
    case 'created':
    case 'processing':
    default: return '继续推进'
  }
}

function handleProjectClick(proj) {
  handleProjectAction(proj)
}

function handleProjectAction(proj) {
  const pid = proj.project_id
  switch (proj.status) {
    case 'completed':
      // 尝试跳到判决报告
      router.push({ name: 'VerdictGenerate', query: { projectId: pid } })
      break
    case 'running':
      // 获取该项目关联的 simulation_id（暂时跳到准备页让用户进入）
      router.push({ name: 'LexSimPrepare', params: { projectId: pid } })
      break
    default:
      router.push({ name: 'LexSimPrepare', params: { projectId: pid } })
  }
}

function formatDate(dateStr) {
  if (!dateStr) return '—'
  try {
    const d = new Date(dateStr)
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
  } catch {
    return dateStr.slice(0, 10) || '—'
  }
}

function scrollTo(id) {
  const el = document.getElementById(id)
  if (el) el.scrollIntoView({ behavior: 'smooth' })
}

// ---- 粒子背景 ----
function initCanvas() {
  const canvas = bgCanvas.value
  if (!canvas) return
  const ctx = canvas.getContext('2d')
  let W, H

  function resize() {
    W = canvas.width = window.innerWidth
    H = canvas.height = window.innerHeight
  }
  resize()
  window.addEventListener('resize', resize)

  // 生成粒子
  particles = Array.from({ length: 60 }, () => ({
    x: Math.random() * W,
    y: Math.random() * H,
    vx: (Math.random() - 0.5) * 0.3,
    vy: (Math.random() - 0.5) * 0.3,
    r: Math.random() * 1.5 + 0.5,
    alpha: Math.random() * 0.4 + 0.1,
  }))

  function draw() {
    ctx.clearRect(0, 0, W, H)
    // 画连线
    for (let i = 0; i < particles.length; i++) {
      for (let j = i + 1; j < particles.length; j++) {
        const dx = particles[i].x - particles[j].x
        const dy = particles[i].y - particles[j].y
        const dist = Math.sqrt(dx * dx + dy * dy)
        if (dist < 130) {
          ctx.beginPath()
          ctx.strokeStyle = `rgba(59,130,246,${0.08 * (1 - dist / 130)})`
          ctx.lineWidth = 0.8
          ctx.moveTo(particles[i].x, particles[i].y)
          ctx.lineTo(particles[j].x, particles[j].y)
          ctx.stroke()
        }
      }
    }
    // 画点
    particles.forEach(p => {
      p.x += p.vx
      p.y += p.vy
      if (p.x < 0 || p.x > W) p.vx *= -1
      if (p.y < 0 || p.y > H) p.vy *= -1
      ctx.beginPath()
      ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2)
      ctx.fillStyle = `rgba(96,165,250,${p.alpha})`
      ctx.fill()
    })
    animFrame = requestAnimationFrame(draw)
  }
  draw()
}

onMounted(() => {
  initCanvas()
  fetchProjects()
  fetchSimulationCount()
})

onBeforeUnmount(() => {
  if (animFrame) cancelAnimationFrame(animFrame)
})
</script>

<style scoped>
/* ===== 基础 ===== */
.home-view {
  min-height: 100vh;
  background: #070d14;
  color: #e2e8f0;
  font-family: 'PingFang SC', 'Microsoft YaHei', system-ui, sans-serif;
  position: relative;
  overflow-x: hidden;
}

.bg-canvas {
  position: fixed;
  inset: 0;
  z-index: 0;
  pointer-events: none;
}

/* ===== HERO ===== */
.hero {
  position: relative;
  z-index: 1;
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 48px;
  max-width: 1280px;
  margin: 0 auto;
  padding: 80px 48px 60px;
}

@media (max-width: 1024px) {
  .hero { flex-direction: column; padding: 80px 24px 60px; text-align: center; }
  .hero-visual { display: none; }
}

.hero-content { flex: 1; max-width: 620px; }

.hero-badge {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: rgba(59,130,246,0.12);
  border: 1px solid rgba(59,130,246,0.3);
  border-radius: 100px;
  padding: 6px 16px;
  font-size: 13px;
  color: #60a5fa;
  margin-bottom: 24px;
  letter-spacing: 0.5px;
}

.badge-dot {
  width: 6px; height: 6px;
  border-radius: 50%;
  background: #3b82f6;
  animation: pulse-dot 2s infinite;
}

@keyframes pulse-dot {
  0%, 100% { opacity: 1; transform: scale(1); }
  50% { opacity: 0.5; transform: scale(1.4); }
}

/* 天平 SVG */
.hero-logo { margin-bottom: 16px; }
.scales-svg { width: 100px; height: 90px; filter: drop-shadow(0 0 12px rgba(59,130,246,0.5)); }

.beam-group { animation: sway 4s ease-in-out infinite; transform-origin: 100px 55px; }
@keyframes sway {
  0%, 100% { transform: rotate(-3deg); }
  50% { transform: rotate(3deg); }
}
.star-1 { animation: twinkle 2.5s ease-in-out infinite; }
.star-2 { animation: twinkle 3.1s ease-in-out infinite 0.5s; }
.star-3 { animation: twinkle 2.8s ease-in-out infinite 1s; }
@keyframes twinkle {
  0%, 100% { opacity: 0.3; transform: scale(1); }
  50% { opacity: 1; transform: scale(1.5); }
}

/* 标题 */
.hero-title {
  font-size: 72px;
  font-weight: 900;
  letter-spacing: -2px;
  line-height: 1;
  margin: 0 0 8px;
}
.title-lex {
  background: linear-gradient(135deg, #60a5fa, #3b82f6);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}
.title-sim {
  background: linear-gradient(135deg, #a78bfa, #7c3aed);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.hero-sub {
  font-size: 20px;
  color: #94a3b8;
  margin: 0 0 20px;
  font-weight: 400;
  letter-spacing: 1px;
}

.hero-desc {
  font-size: 16px;
  color: #64748b;
  line-height: 1.8;
  margin: 0 0 36px;
}

/* 按钮 */
.hero-actions { display: flex; gap: 16px; align-items: center; margin-bottom: 48px; }

.btn-primary {
  display: inline-flex; align-items: center; gap: 8px;
  background: linear-gradient(135deg, #3b82f6, #2563eb);
  color: #fff;
  border: none;
  border-radius: 12px;
  padding: 14px 28px;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.25s;
  box-shadow: 0 4px 24px rgba(59,130,246,0.35);
}
.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 32px rgba(59,130,246,0.5);
}
.btn-primary.sm { padding: 10px 20px; font-size: 14px; }

.btn-ghost {
  background: transparent;
  color: #94a3b8;
  border: 1px solid #1e3a5f;
  border-radius: 12px;
  padding: 14px 24px;
  font-size: 15px;
  cursor: pointer;
  transition: all 0.25s;
}
.btn-ghost:hover { border-color: #3b82f6; color: #60a5fa; }

.btn-icon { width: 18px; height: 18px; }

/* 统计 */
.hero-stats {
  display: flex;
  align-items: center;
  gap: 24px;
}
.stat-item { text-align: center; }
.stat-num {
  display: block;
  font-size: 28px;
  font-weight: 800;
  background: linear-gradient(135deg, #60a5fa, #a78bfa);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}
.stat-label { font-size: 12px; color: #64748b; margin-top: 2px; display: block; }
.stat-divider { width: 1px; height: 36px; background: #1e3a5f; }

/* ===== 右侧视觉 ===== */
.hero-visual {
  flex: 0 0 420px;
  position: relative;
  height: 480px;
}

.visual-card {
  position: absolute;
  background: rgba(15, 25, 35, 0.9);
  backdrop-filter: blur(12px);
  border: 1px solid #1e3a5f;
  border-radius: 16px;
  padding: 20px;
  box-shadow: 0 8px 40px rgba(0,0,0,0.4);
}

.card-main {
  width: 340px; top: 40px; left: 0;
  animation: float 5s ease-in-out infinite;
}
@keyframes float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
}

.card-sub {
  width: 160px;
  animation: float 5s ease-in-out infinite;
}
.card-sub1 { bottom: 60px; right: 0; animation-delay: 1s; }
.card-sub2 { bottom: -20px; left: 180px; animation-delay: 2s; }

.vc-header {
  display: flex; align-items: center; gap: 8px; margin-bottom: 14px;
}
.vc-dot {
  width: 10px; height: 10px; border-radius: 50%;
}
.vc-dot.green { background: #10b981; }
.vc-dot.yellow { background: #f59e0b; }
.vc-dot.red { background: #ef4444; }
.vc-title { font-size: 12px; color: #64748b; margin-left: auto; }

.vc-roles { display: flex; flex-direction: column; gap: 6px; margin-bottom: 14px; }
.role-pill {
  display: flex; align-items: center; gap: 8px;
  background: rgba(255,255,255,0.03);
  border: 1px solid rgba(255,255,255,0.06);
  border-radius: 8px;
  padding: 6px 10px;
  font-size: 12px;
}
.role-avatar { font-size: 14px; }
.role-status {
  margin-left: auto;
  font-size: 11px;
  color: #64748b;
  background: #0f1923;
  padding: 2px 7px;
  border-radius: 100px;
}
.role-status.pulse {
  color: #10b981;
  background: rgba(16,185,129,0.1);
  animation: status-pulse 1.5s ease-in-out infinite;
}
@keyframes status-pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.vc-speech { margin-bottom: 14px; }
.speech-line { font-size: 12px; display: flex; gap: 8px; align-items: flex-start; }
.speech-line.mt { margin-top: 8px; }
.sl-role { font-weight: 600; white-space: nowrap; }
.sl-text { color: #94a3b8; line-height: 1.5; }

.vc-progress { display: flex; align-items: center; gap: 8px; }
.vcp-label { font-size: 11px; color: #64748b; white-space: nowrap; }
.vcp-bar { flex: 1; height: 4px; background: #1e3a5f; border-radius: 2px; overflow: hidden; }
.vcp-fill { height: 100%; background: linear-gradient(90deg, #3b82f6, #a78bfa); border-radius: 2px; }
.vcp-pct { font-size: 11px; color: #60a5fa; white-space: nowrap; }

.sub-icon { font-size: 24px; margin-bottom: 8px; }
.sub-title { font-size: 12px; color: #64748b; margin-bottom: 4px; }
.sub-val { font-size: 14px; font-weight: 600; color: #e2e8f0; }
.sub-val b { color: #60a5fa; }

/* ===== section 通用 ===== */
section { position: relative; z-index: 1; max-width: 1280px; margin: 0 auto; padding: 80px 48px; }

.section-header { text-align: center; margin-bottom: 56px; }
.section-badge {
  display: inline-block;
  background: rgba(59,130,246,0.1);
  border: 1px solid rgba(59,130,246,0.25);
  border-radius: 100px;
  padding: 4px 16px;
  font-size: 13px;
  color: #60a5fa;
  margin-bottom: 16px;
  letter-spacing: 0.5px;
}
.section-title {
  font-size: 40px;
  font-weight: 800;
  color: #f1f5f9;
  margin: 0 0 16px;
  letter-spacing: -1px;
}
.section-desc { font-size: 15px; color: #64748b; max-width: 520px; margin: 0 auto; line-height: 1.7; }

/* ===== 特性 ===== */
.features-section { background: linear-gradient(180deg, transparent, rgba(15,25,35,0.5) 50%, transparent); }
.features-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 24px;
}
@media (max-width: 900px) { .features-grid { grid-template-columns: repeat(2, 1fr); } }
@media (max-width: 600px) { .features-grid { grid-template-columns: 1fr; } }

.feat-card {
  background: rgba(15,25,35,0.8);
  border: 1px solid #1e3a5f;
  border-radius: 16px;
  padding: 28px;
  transition: all 0.3s;
  position: relative;
  overflow: hidden;
}
.feat-card::before {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, var(--accent, #3b82f6)08, transparent);
  opacity: 0;
  transition: opacity 0.3s;
}
.feat-card:hover {
  border-color: var(--accent, #3b82f6);
  transform: translateY(-4px);
  box-shadow: 0 12px 40px rgba(0,0,0,0.3);
}
.feat-card:hover::before { opacity: 1; }

.feat-icon-wrap { position: relative; margin-bottom: 16px; display: inline-block; }
.feat-icon { font-size: 32px; position: relative; z-index: 1; }
.feat-glow {
  position: absolute;
  inset: -8px;
  background: radial-gradient(circle, var(--accent, #3b82f6)20, transparent 70%);
  filter: blur(8px);
  border-radius: 50%;
}

.feat-title { font-size: 17px; font-weight: 700; color: #f1f5f9; margin: 0 0 10px; }
.feat-desc { font-size: 13px; color: #64748b; line-height: 1.7; margin: 0 0 14px; }
.feat-tags { display: flex; flex-wrap: wrap; gap: 6px; }
.feat-tag {
  font-size: 11px;
  background: rgba(59,130,246,0.1);
  border: 1px solid rgba(59,130,246,0.2);
  color: #60a5fa;
  border-radius: 100px;
  padding: 3px 10px;
}

/* ===== 工作流程 ===== */
.workflow-section { padding-top: 0; }
.workflow-steps {
  display: flex;
  align-items: flex-start;
  justify-content: center;
  gap: 0;
  position: relative;
}

.ws-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex: 1;
  position: relative;
}

.ws-line {
  position: absolute;
  top: 28px;
  left: 50%;
  width: 100%;
  height: 2px;
  background: linear-gradient(90deg, #1e3a5f 0%, #3b82f6 50%, #1e3a5f 100%);
  z-index: 0;
}

.ws-circle {
  width: 56px; height: 56px;
  border-radius: 50%;
  background: rgba(15,25,35,0.9);
  border: 2px solid var(--sc, #3b82f6);
  display: flex; align-items: center; justify-content: center;
  font-size: 16px; font-weight: 800; color: var(--sc, #3b82f6);
  z-index: 1;
  box-shadow: 0 0 20px var(--sc, #3b82f6)30;
  margin-bottom: 20px;
}

.ws-content { text-align: center; padding: 0 8px; }
.ws-icon { font-size: 28px; margin-bottom: 8px; }
.ws-title { font-size: 15px; font-weight: 700; color: #f1f5f9; margin: 0 0 6px; }
.ws-desc { font-size: 12px; color: #64748b; line-height: 1.6; }

/* ===== 历史案件 ===== */
.history-section {
  border-top: 1px solid #1e3a5f;
  margin: 0 auto;
  padding: 80px 48px;
  max-width: 1280px;
}

.loading-state {
  display: flex; align-items: center; justify-content: center; gap: 12px;
  height: 160px; color: #64748b;
}
.loading-spinner {
  width: 24px; height: 24px;
  border: 2px solid #1e3a5f;
  border-top-color: #3b82f6;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }

.empty-state {
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  gap: 12px; height: 240px; color: #64748b;
}
.empty-icon { font-size: 48px; filter: grayscale(0.5); }
.empty-state h3 { font-size: 18px; color: #94a3b8; margin: 0; }
.empty-state p { font-size: 14px; margin: 0; }

.history-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 24px;
}

.hist-card {
  background: rgba(15,25,35,0.9);
  border: 1px solid #1e3a5f;
  border-radius: 16px;
  padding: 28px;
  cursor: pointer;
  transition: all 0.3s;
  position: relative;
  overflow: hidden;
}
.hist-card:hover {
  border-color: #3b82f6;
  transform: translateY(-3px);
  box-shadow: 0 8px 32px rgba(59,130,246,0.15);
}
.hist-card.status-running { border-color: rgba(16,185,129,0.3); }
.hist-card.status-running:hover { border-color: #10b981; box-shadow: 0 8px 32px rgba(16,185,129,0.15); }
.hist-card.status-error { border-color: rgba(239,68,68,0.3); }

.hc-header {
  display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px;
}
.hc-type-badge {
  font-size: 11px;
  padding: 3px 10px;
  border-radius: 100px;
  font-weight: 600;
}
.hc-type-badge.criminal {
  background: rgba(168,85,247,0.15);
  color: #a855f7;
  border: 1px solid rgba(168,85,247,0.3);
}
.hc-type-badge.civil {
  background: rgba(59,130,246,0.15);
  color: #60a5fa;
  border: 1px solid rgba(59,130,246,0.3);
}
.hc-type-badge.general {
  background: rgba(100,116,139,0.15);
  color: #94a3b8;
  border: 1px solid rgba(100,116,139,0.3);
}

.hc-status-dot {
  width: 8px; height: 8px; border-radius: 50%;
}
.hc-status-dot.running { background: #10b981; animation: pulse-dot 2s infinite; }
.hc-status-dot.completed { background: #3b82f6; }
.hc-status-dot.error { background: #ef4444; }
.hc-status-dot.created, .hc-status-dot.processing { background: #f59e0b; animation: pulse-dot 2s infinite; }
.hc-status-dot.prepared, .hc-status-dot.graph_built { background: #a855f7; }

.hc-name {
  font-size: 15px;
  font-weight: 700;
  color: #f1f5f9;
  margin: 0 0 12px;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  line-height: 1.5;
}

.hc-meta { display: flex; flex-direction: column; gap: 6px; margin-bottom: 12px; }
.hc-meta-row { display: flex; align-items: center; gap: 6px; font-size: 12px; color: #64748b; }
.meta-icon { width: 12px; height: 12px; flex-shrink: 0; }

.hc-status-label {
  display: flex; align-items: center; gap: 6px;
  font-size: 12px; color: #94a3b8;
  margin-bottom: 16px;
}
.hc-sl-dot {
  width: 6px; height: 6px; border-radius: 50%;
}
.hc-sl-dot.running { background: #10b981; }
.hc-sl-dot.completed { background: #3b82f6; }
.hc-sl-dot.error { background: #ef4444; }
.hc-sl-dot.created, .hc-sl-dot.processing { background: #f59e0b; }
.hc-sl-dot.prepared, .hc-sl-dot.graph_built { background: #a855f7; }

.hc-actions { }
.hc-btn {
  width: 100%;
  padding: 9px 16px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  border: none;
}
.hc-btn.primary {
  background: rgba(59,130,246,0.15);
  color: #60a5fa;
  border: 1px solid rgba(59,130,246,0.3);
}
.hc-btn.primary:hover {
  background: rgba(59,130,246,0.25);
  border-color: #3b82f6;
}

.hc-deco-line {
  position: absolute;
  left: 0; bottom: 0;
  width: 0; height: 2px;
  background: linear-gradient(90deg, #3b82f6, #a78bfa);
  border-radius: 0 0 0 16px;
  transition: width 0.4s ease;
}
.hist-card:hover .hc-deco-line { width: 100%; }

/* 新建卡片 */
.new-card {
  border-style: dashed;
  border-color: #1e3a5f;
  background: rgba(15,25,35,0.4);
  display: flex; align-items: center; justify-content: center;
  min-height: 200px;
}
.new-card:hover { border-color: #3b82f6; background: rgba(59,130,246,0.05); }
.new-card-inner { text-align: center; color: #64748b; }
.new-icon {
  font-size: 36px; font-weight: 300; color: #1e3a5f;
  margin-bottom: 8px; line-height: 1;
  transition: color 0.3s;
}
.new-card:hover .new-icon { color: #3b82f6; }
.new-card-inner h3 { font-size: 15px; color: #94a3b8; margin: 0 0 4px; }
.new-card-inner p { font-size: 12px; margin: 0; }

/* ===== 更多历史 ===== */
.history-more {
  text-align: center;
  margin-top: 32px;
}
.btn-more {
  background: transparent;
  border: 1px solid rgba(59,130,246,0.4);
  color: #60a5fa;
  border-radius: 100px;
  padding: 10px 32px;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.25s;
  letter-spacing: 0.3px;
}
.btn-more:hover {
  background: rgba(59,130,246,0.1);
  border-color: #3b82f6;
}

/* ===== footer ===== */
.home-footer {
  position: relative; z-index: 1;
  text-align: center;
  padding: 40px 48px;
  border-top: 1px solid #1e3a5f;
  max-width: 1280px;
  margin: 0 auto;
}
.footer-logo { font-size: 24px; font-weight: 900; margin-bottom: 8px; }
.footer-desc { font-size: 13px; color: #64748b; margin: 0; }
</style>
