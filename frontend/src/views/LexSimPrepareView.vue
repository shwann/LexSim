<template>
  <div class="prepare-view">
    <!-- 顶部导航 -->
    <header class="prepare-header">
      <button class="btn-back" @click="router.push('/lexsim/create')">← 返回</button>
      <div class="header-title">
        <span class="header-icon">⚖</span>
        <div>
          <h1 class="header-h1">{{ caseName || '法律庭审模拟' }}</h1>
          <span class="header-sub">
            <span class="case-type-badge">{{ caseTypeLabel }}</span>
            <span class="project-id">{{ projectId }}</span>
          </span>
        </div>
      </div>
      <div class="header-progress">
        <span class="progress-label">整体进度</span>
        <span class="progress-value">{{ overallProgressText }}</span>
      </div>
    </header>

    <!-- 主体：流水线步骤 -->
    <div class="prepare-body">
      <div class="pipeline">
        <!-- Step 1：加载法律本体 -->
        <div class="pipeline-step" :class="getStepClass(0)">
          <div class="step-header">
            <div class="step-indicator">
              <span v-if="steps[0].status === 'done'" class="step-icon done">✓</span>
              <span v-else-if="steps[0].status === 'running'" class="step-icon running">
                <span class="spinner-sm" />
              </span>
              <span v-else-if="steps[0].status === 'error'" class="step-icon error">✕</span>
              <span v-else class="step-num">1</span>
            </div>
            <div class="step-info">
              <div class="step-title">加载法律本体</div>
              <div class="step-desc">按案件类型（民事 / 刑事）加载预置实体与关系模板，无需 AI 生成</div>
            </div>
            <div class="step-badge" :class="`badge-${steps[0].status}`">{{ stepLabel(0) }}</div>
          </div>
          <div v-if="steps[0].status === 'done' && ontologyInfo" class="step-result">
            <span class="result-tag">实体类型 {{ ontologyInfo.entity_types_count }} 个</span>
            <span class="result-tag">关系类型 {{ ontologyInfo.edge_types_count }} 个</span>
            <span class="result-tag">{{ caseTypeLabel }}模板</span>
          </div>

          <!-- 本体类型详情（直接展示，无需点击） -->
          <div v-if="steps[0].status === 'done'" class="ontology-detail-panel">
            <div class="ontology-section-title">实体类型</div>
            <div class="ontology-type-grid">
              <div
                v-for="et in ONTOLOGY_STATIC[caseType].entity_types"
                :key="et.name"
                class="ontology-type-item"
              >
                <span class="otype-name">{{ et.name }}</span>
                <span class="otype-desc">{{ et.desc }}</span>
              </div>
            </div>
            <div class="ontology-section-title" style="margin-top:12px">关系类型</div>
            <div class="ontology-type-grid">
              <div
                v-for="et in ONTOLOGY_STATIC[caseType].edge_types"
                :key="et.name"
                class="ontology-type-item edge-type"
              >
                <span class="otype-name">{{ et.name }}</span>
                <span class="otype-desc">{{ et.desc }}</span>
              </div>
            </div>
          </div>

          <div v-if="steps[0].status === 'error'" class="step-error">{{ steps[0].error }}</div>
        </div>

        <div class="pipeline-connector" :class="{ active: steps[0].status === 'done' }" />

        <!-- Step 2：构建案件图谱 -->
        <div class="pipeline-step" :class="getStepClass(1)">
          <div class="step-header">
            <div class="step-indicator">
              <span v-if="steps[1].status === 'done'" class="step-icon done">✓</span>
              <span v-else-if="steps[1].status === 'running'" class="step-icon running">
                <span class="spinner-sm" />
              </span>
              <span v-else-if="steps[1].status === 'error'" class="step-icon error">✕</span>
              <span v-else class="step-num">2</span>
            </div>
            <div class="step-info">
              <div class="step-title">构建案件知识图谱</div>
              <div class="step-desc">从案件材料中提取涉案人员、证据、事件等关键信息，构建结构化知识图谱</div>
            </div>
            <div class="step-badge" :class="`badge-${steps[1].status}`">{{ stepLabel(1) }}</div>
          </div>
          <div v-if="steps[1].status === 'running'" class="step-progress-wrap">
            <div class="progress-track">
              <div class="progress-fill" :style="{ width: steps[1].progress + '%' }" />
            </div>
            <span class="progress-pct">{{ steps[1].progress }}%</span>
            <span class="progress-msg">{{ steps[1].message }}</span>
          </div>
          <div v-if="steps[1].status === 'done' && graphInfo" class="step-result">
            <span class="result-tag">{{ graphInfo.node_count }} 个实体节点</span>
            <span class="result-tag">{{ graphInfo.edge_count }} 条关系边</span>
            <span class="result-tag graph-id-tag">图谱已就绪</span>
          </div>

          <!-- 图谱实体列表（直接展示，无需点击） -->
          <div v-if="steps[1].status === 'done'" class="entities-panel">
            <div v-if="entitiesLoading" class="profiles-loading">
              <span class="spinner-sm" /> 加载实体数据...
            </div>
            <div v-else-if="Object.keys(entitiesByType).length === 0" class="profiles-empty">暂无实体数据</div>
            <div v-else class="entities-content">
              <div
                v-for="(group, typeName) in entitiesByType"
                :key="typeName"
                class="entity-group"
              >
                <div class="entity-type-header">
                  <span class="entity-type-name">{{ typeName }}</span>
                  <span class="entity-type-count">{{ group.length }} 个</span>
                </div>
                <div class="entity-list">
                  <div
                    v-for="(entity, ei) in group"
                    :key="ei"
                    class="entity-item"
                  >
                    <span class="entity-dot">·</span>
                    <span class="entity-name">{{ entity.name }}</span>
                    <span v-if="entity.summary" class="entity-summary">{{ entity.summary }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div v-if="steps[1].status === 'error'" class="step-error">{{ steps[1].error }}</div>
        </div>

        <div class="pipeline-connector" :class="{ active: steps[1].status === 'done' }" />

        <!-- Step 3：生成庭审配置 -->
        <div class="pipeline-step" :class="getStepClass(2)">
          <div class="step-header">
            <div class="step-indicator">
              <span v-if="steps[2].status === 'done'" class="step-icon done">✓</span>
              <span v-else-if="steps[2].status === 'running'" class="step-icon running">
                <span class="spinner-sm" />
              </span>
              <span v-else-if="steps[2].status === 'error'" class="step-icon error">✕</span>
              <span v-else class="step-num">3</span>
            </div>
            <div class="step-info">
              <div class="step-title">生成庭审配置</div>
              <div class="step-desc">为每位参与者生成法庭角色人设与行为约束，构建 13 轮完整庭审流程参数</div>
            </div>
            <div class="step-badge" :class="`badge-${steps[2].status}`">{{ stepLabel(2) }}</div>
          </div>
          <div v-if="steps[2].status === 'running'" class="step-progress-wrap">
            <div class="progress-track">
              <div class="progress-fill" :style="{ width: steps[2].progress + '%' }" />
            </div>
            <span class="progress-pct">{{ steps[2].progress }}%</span>
            <span class="progress-msg">{{ steps[2].message }}</span>
          </div>
          <div v-if="steps[2].status === 'done' && prepareInfo" class="step-result">
            <span class="result-tag">参与者 {{ prepareInfo.entity_count }} 人</span>
            <span class="result-tag">角色人设 {{ prepareInfo.profile_count }} 份</span>
            <span class="result-tag">13 轮庭审</span>
          </div>

          <!-- 角色人设卡片列表（直接展示） -->
          <div v-if="steps[2].status === 'done'" class="profiles-panel">
            <div class="section-label">角色人设</div>
            <div v-if="profilesLoading" class="profiles-loading">
              <span class="spinner-sm" /> 加载人设数据...
            </div>
            <div v-else-if="profiles.length === 0" class="profiles-empty">暂无人设数据</div>
            <div v-else class="profiles-grid">
              <div
                v-for="(p, i) in profiles"
                :key="i"
                class="profile-card"
                :class="'role-' + (p.court_role || 'other')"
              >
                <div class="profile-card-header">
                  <div class="profile-avatar" :class="'avatar-' + (p.court_role || 'other')">
                    {{ getCourtRoleInitial(p.court_role) }}
                  </div>
                  <div class="profile-name-block">
                    <div class="profile-name">{{ p.name || p.agent_name || '参与者' + (i+1) }}</div>
                    <div class="profile-role-badge">{{ COURT_ROLE_LABELS[p.court_role] || p.court_role || '未知角色' }}</div>
                  </div>
                  <div v-if="p.profession" class="profile-profession">{{ p.profession }}</div>
                </div>
                <div v-if="p.bio" class="profile-bio">{{ p.bio }}</div>
                <div v-if="p.interested_topics && p.interested_topics.length" class="profile-topics">
                  <span
                    v-for="(t, ti) in p.interested_topics.filter(t => !t.startsWith('court_role'))"
                    :key="ti"
                    class="topic-tag"
                  >{{ t }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- 庭审流程表（直接展示，紧接在角色人设下方） -->
          <div v-if="steps[2].status === 'done'" class="flow-panel">
            <div class="section-label">庭审流程</div>
            <div
              v-for="(phase, pi) in COURT_PHASES"
              :key="pi"
              class="flow-phase-block"
            >
              <div class="flow-phase-header" :class="'phase-color-' + pi">
                <span class="flow-phase-index">阶段 {{ pi + 1 }}</span>
                <span class="flow-phase-name">{{ phase.name }}</span>
                <span class="flow-phase-rounds">第 {{ phase.rounds[0] + 1 }}~{{ phase.rounds[phase.rounds.length-1] + 1 }} 轮</span>
              </div>
              <div class="flow-phase-desc">{{ phase.desc }}</div>
              <div class="flow-round-list">
                <div
                  v-for="rn in phase.rounds"
                  :key="rn"
                  class="flow-round-item"
                >
                  <span class="flow-round-num">R{{ rn }}</span>
                  <span class="flow-round-label">{{ phase.roundLabels[rn - phase.rounds[0]] || phase.name }}</span>
                  <div class="flow-round-roles">
                    <span
                      v-for="role in phase.activeRoles"
                      :key="role"
                      class="flow-role-badge"
                      :class="'role-' + role"
                    >{{ COURT_ROLE_LABELS[role] }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div v-if="steps[2].status === 'error'" class="step-error">{{ steps[2].error }}</div>
        </div>

        <div class="pipeline-connector" :class="{ active: steps[2].status === 'done' }" />

        <!-- Step 4：启动庭审 -->
        <div class="pipeline-step" :class="getStepClass(3)">
          <div class="step-header">
            <div class="step-indicator">
              <span v-if="steps[3].status === 'done'" class="step-icon done">✓</span>
              <span v-else-if="steps[3].status === 'running'" class="step-icon running">
                <span class="spinner-sm" />
              </span>
              <span v-else-if="steps[3].status === 'error'" class="step-icon error">✕</span>
              <span v-else class="step-num">4</span>
            </div>
            <div class="step-info">
              <div class="step-title">启动庭审模拟</div>
              <div class="step-desc">AI 多智能体正式开庭，实时显示各方发言，全程覆盖开庭准备到宣判</div>
            </div>
            <div class="step-badge" :class="`badge-${steps[3].status}`">{{ stepLabel(3) }}</div>
          </div>

          <!-- 等待就绪：显示启动按钮 -->
          <div v-if="allPrepDone && steps[3].status === 'pending'" class="start-area">
            <button class="btn-start" @click="startSimulation">
              ▶ 开始庭审模拟
            </button>
            <span class="start-hint">点击后进入庭审实时视图，AI 将模拟完整庭审过程</span>
          </div>

          <!-- 已启动：显示进入按钮 -->
          <div v-if="steps[3].status === 'done'" class="start-area">
            <button class="btn-start btn-enter" @click="goToCourt">
              ▶ 进入庭审实时视图
            </button>
            <span class="start-hint">庭审已启动，点击进入实时查看庭审过程</span>
          </div>

          <div v-if="steps[3].status === 'error'" class="step-error">{{ steps[3].error }}</div>
        </div>
      </div>

      <!-- 操作栏 -->
      <div class="action-bar">
        <!-- 错误重试 -->
        <button v-if="hasError" class="btn-retry" @click="retryFromError">↺ 从失败步骤重试</button>
        <!-- 全部完成后允许重新执行 -->
        <button v-if="allDone" class="btn-rerun" @click="confirmRerunAll">↺ 重新执行全部步骤</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import axios from 'axios'

const BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5001'

const route = useRoute()
const router = useRouter()

const projectId = computed(() => route.params.projectId)
const caseName = computed(() => route.query.caseName || '')
const caseType = computed(() => route.query.caseType || 'civil')
const caseTypeLabel = computed(() =>
  ({ civil: '民事案件', criminal: '刑事案件' }[caseType.value] || '案件')
)

// 流水线步骤状态：pending / running / done / error
const steps = ref([
  { status: 'pending', progress: 0, message: '', error: '' },
  { status: 'pending', progress: 0, message: '', error: '' },
  { status: 'pending', progress: 0, message: '', error: '' },
  { status: 'pending', progress: 0, message: '', error: '' },
])

// 步骤结果数据
const ontologyInfo = ref(null)
const graphInfo = ref(null)
const prepareInfo = ref(null)

const ONTOLOGY_STATIC = {
  civil: {
    entity_types: [
      { name: 'Judge',        desc: '主审法官/仲裁员' },
      { name: 'Lawyer',       desc: '当事方代理律师' },
      { name: 'Plaintiff',    desc: '原告方' },
      { name: 'Defendant',    desc: '被告方' },
      { name: 'Witness',      desc: '证人/出庭陈述' },
      { name: 'Expert',       desc: '专家证人/鉴定人' },
      { name: 'Evidence',     desc: '书证、物证、电子数据等' },
      { name: 'Court',        desc: '审理本案的法院' },
      { name: 'Person',       desc: '其他涉案自然人' },
      { name: 'Organization', desc: '其他涉案机构/单位' },
    ],
    edge_types: [
      { name: 'REPRESENTS',    desc: '律师代理当事人' },
      { name: 'SUBMITS',       desc: '提交证据' },
      { name: 'TESTIFIES_FOR', desc: '出庭为一方作证' },
      { name: 'CONTRADICTS',   desc: '证据/陈述相互矛盾' },
      { name: 'SUPPORTS',      desc: '证据支持某方主张' },
      { name: 'FILES_AGAINST', desc: '原告起诉被告' },
      { name: 'EMPLOYED_BY',   desc: '雇佣/劳动关系' },
      { name: 'OWNS',          desc: '所有权关系' },
      { name: 'CONTRACTS_WITH',desc: '合同关系' },
      { name: 'WITNESSED',     desc: '目击/知晓某事件' },
    ],
  },
  criminal: {
    entity_types: [
      { name: 'Judge',         desc: '刑事案件主审法官' },
      { name: 'Prosecutor',    desc: '公诉检察官' },
      { name: 'DefenseLawyer', desc: '辩护律师' },
      { name: 'Defendant',     desc: '被告人/被追诉人' },
      { name: 'Victim',        desc: '被害人/受害方' },
      { name: 'Witness',       desc: '证人/出庭陈述' },
      { name: 'Expert',        desc: '法医/技术鉴定专家' },
      { name: 'Court',         desc: '审理本案的法院' },
      { name: 'Person',        desc: '其他涉案自然人' },
      { name: 'Organization',  desc: '其他涉案机构/单位' },
    ],
    edge_types: [
      { name: 'DEFENDS',           desc: '辩护律师为被告辩护' },
      { name: 'PROSECUTES',        desc: '检察官提起公诉' },
      { name: 'TESTIFIES_AGAINST', desc: '证人/被害人指证' },
      { name: 'TESTIFIES_FOR',     desc: '证人为被告作证' },
      { name: 'HARMED_BY',         desc: '被害人被告伤害' },
      { name: 'COMMITTED',         desc: '被告实施犯罪行为' },
      { name: 'WITNESSED',         desc: '目击/知晓犯罪过程' },
      { name: 'PROVIDES_EVIDENCE', desc: '提供技术鉴定意见' },
      { name: 'ACCOMPLICE_OF',     desc: '共同犯罪关系' },
      { name: 'VICTIM_OF',         desc: '受害关系' },
    ],
  },
}

// 图谱实体
const entitiesByType = ref({})
const entitiesLoading = ref(false)

// 角色人设
const showProfiles = ref(false)
const profiles = ref([])
const profilesLoading = ref(false)

// 庭审 13 轮流程（固定结构）
const COURT_PHASES = [
  {
    name: '开庭准备',
    desc: '法官宣布开庭，核实双方身份，告知诉讼权利义务，确认庭审范围。',
    rounds: [0, 1],
    roundLabels: ['宣布开庭·告知权利', '确认身份·庭审事项'],
    activeRoles: ['judge', 'plaintiff', 'defendant', 'plaintiff_counsel', 'defense_counsel'],
  },
  {
    name: '法庭调查',
    desc: '各方陈述案情，举证、质证，询问证人和专家，对证据进行辩论。',
    rounds: [2, 3, 4, 5, 6],
    roundLabels: ['原告陈述', '被告答辩', '原告举证', '被告质证·举证', '证人/专家询问'],
    activeRoles: ['judge', 'plaintiff', 'defendant', 'plaintiff_counsel', 'defense_counsel', 'witness', 'expert'],
  },
  {
    name: '法庭辩论',
    desc: '各方就事实认定和法律适用进行辩论，充分表达各自立场。',
    rounds: [7, 8, 9],
    roundLabels: ['原告辩论意见', '被告辩论意见', '互相反驳·总结'],
    activeRoles: ['judge', 'plaintiff_counsel', 'defense_counsel', 'plaintiff', 'defendant'],
  },
  {
    name: '最后陈述',
    desc: '法官宣布辩论终结，被告人作最后陈述，各方提出最终意见。',
    rounds: [10],
    roundLabels: ['最终意见陈述'],
    activeRoles: ['judge', 'plaintiff', 'defendant', 'plaintiff_counsel', 'defense_counsel'],
  },
  {
    name: '休庭评议',
    desc: '法官(合议庭)退庭合议，综合全案证据与辩论意见形成判决意见。',
    rounds: [11],
    roundLabels: ['合议庭评议'],
    activeRoles: ['judge'],
  },
  {
    name: '宣判',
    desc: '法官宣读判决结果，告知上诉权利和上诉期限。',
    rounds: [12],
    roundLabels: ['宣读判决·告知权利'],
    activeRoles: ['judge', 'plaintiff', 'defendant'],
  },
]

const COURT_ROLE_LABELS = {
  judge:            '法官',
  plaintiff_counsel:'原告律师',
  defense_counsel:  '被告律师',
  prosecutor:       '检察官',
  plaintiff:        '原告',
  defendant:        '被告',
  victim:           '受害人',
  witness:          '证人',
  expert:           '专家',
  court:            '法院',
  other:            '其他',
}

const COURT_ROLE_INITIALS = {
  judge: '官', plaintiff_counsel: '原', defense_counsel: '辩',
  prosecutor: '检', plaintiff: '原', defendant: '被',
  victim: '受', witness: '证', expert: '专', court: '院', other: '他',
}

function getCourtRoleInitial(role) {
  return COURT_ROLE_INITIALS[role] || '人'
}

// 内部存储（同时从 URL query 恢复，支持刷新）
let graphId = route.query.graphId || ''
let simulationId = route.query.simulationId || ''
let pollTimer = null

const allPrepDone = computed(() =>
  steps.value[0].status === 'done' &&
  steps.value[1].status === 'done' &&
  steps.value[2].status === 'done'
)

const allDone = computed(() => steps.value.every(s => s.status === 'done'))

const hasError = computed(() => steps.value.some(s => s.status === 'error'))

const overallProgressText = computed(() => {
  const done = steps.value.filter(s => s.status === 'done').length
  if (done === 4) return '完成'
  if (done === 0 && steps.value[0].status === 'pending') return '准备中'
  return `${done} / 4 步`
})

function getStepClass(idx) {
  const s = steps.value[idx].status
  return {
    'step-pending': s === 'pending',
    'step-running': s === 'running',
    'step-done': s === 'done',
    'step-error': s === 'error',
  }
}

function stepLabel(idx) {
  return { pending: '等待', running: '进行中', done: '完成', error: '失败' }[steps.value[idx].status]
}

// ── 步骤 1：加载法律本体 ──────────────────────────────────────────────
async function runStep1() {
  steps.value[0].status = 'running'
  try {
    const res = await axios.post(
      `${BASE_URL}/api/lexsim/case/${projectId.value}/ontology`,
      { use_template: true }
    )
    ontologyInfo.value = res.data?.data || {}
    steps.value[0].status = 'done'
    runStep2()
  } catch (err) {
    steps.value[0].status = 'error'
    steps.value[0].error = err.response?.data?.error || err.message
  }
}

// ── 步骤 2：构建图谱 ────────────────────────────────────────────────
async function runStep2() {
  steps.value[1].status = 'running'
  steps.value[1].progress = 5
  steps.value[1].message = '正在提交图谱构建任务...'
  try {
    const res = await axios.post(`${BASE_URL}/api/graph/build`, {
      project_id: projectId.value,
    })
    const taskId = res.data?.data?.task_id
    if (!taskId) throw new Error('未获取到任务 ID')
    pollGraphTask(taskId)
  } catch (err) {
    steps.value[1].status = 'error'
    steps.value[1].error = err.response?.data?.error || err.message
  }
}

function pollGraphTask(taskId) {
  if (pollTimer) clearInterval(pollTimer)
  pollTimer = setInterval(async () => {
    try {
      const res = await axios.get(`${BASE_URL}/api/graph/task/${taskId}`)
      const data = res.data?.data || {}
      if (data.progress !== undefined) {
        steps.value[1].progress = Math.min(95, data.progress)
      }
      if (data.message) steps.value[1].message = data.message

      if (data.status === 'completed') {
        clearInterval(pollTimer)
        pollTimer = null
        steps.value[1].progress = 100
        graphId = data.result?.graph_id || ''
        graphInfo.value = {
          graph_id: graphId,
          node_count: data.result?.node_count || 0,
          edge_count: data.result?.edge_count || 0,
        }
        steps.value[1].status = 'done'
        // 将 graphId 写入 URL，防刷新丢失
        router.replace({ query: { ...route.query, graphId } })
        // 预加载实体数据
        loadEntities()
        runStep3()
      } else if (data.status === 'failed') {
        clearInterval(pollTimer)
        pollTimer = null
        steps.value[1].status = 'error'
        steps.value[1].error = data.error || data.message || '图谱构建失败'
      }
    } catch (err) {
      steps.value[1].message = `轮询异常: ${err.message}`
    }
  }, 2000)
}

// ── 步骤 3：准备庭审配置 ─────────────────────────────────────────────
async function runStep3() {
  steps.value[2].status = 'running'
  steps.value[2].progress = 5
  steps.value[2].message = '正在读取图谱实体...'
  try {
    const res = await axios.post(
      `${BASE_URL}/api/lexsim/case/${projectId.value}/prepare`,
      { graph_id: graphId, max_agents: 20 }
    )
    const taskId = res.data?.data?.task_id
    if (!taskId) throw new Error('未获取到任务 ID')
    pollPrepareTask(taskId)
  } catch (err) {
    steps.value[2].status = 'error'
    steps.value[2].error = err.response?.data?.error || err.message
  }
}

function pollPrepareTask(taskId) {
  if (pollTimer) clearInterval(pollTimer)
  pollTimer = setInterval(async () => {
    try {
      const res = await axios.get(
        `${BASE_URL}/api/lexsim/case/prepare/status/${taskId}`
      )
      const data = res.data?.data || {}
      if (data.progress !== undefined) {
        steps.value[2].progress = Math.min(95, data.progress)
      }
      if (data.message) steps.value[2].message = data.message

      if (data.status === 'completed') {
        clearInterval(pollTimer)
        pollTimer = null
        steps.value[2].progress = 100
        simulationId = data.result?.simulation_id || ''
        prepareInfo.value = {
          entity_count: data.result?.entity_count || 0,
          profile_count: data.result?.profile_count || 0,
        }
        steps.value[2].status = 'done'
        // 将 simulationId 写入 URL，防刷新丢失
        router.replace({ query: { ...route.query, simulationId } })
        // 步骤3完成后预加载人设数据
        loadProfiles()
      } else if (data.status === 'failed') {
        clearInterval(pollTimer)
        pollTimer = null
        steps.value[2].status = 'error'
        steps.value[2].error = data.error || data.message || '庭审准备失败'
      }
    } catch (err) {
      steps.value[2].message = `轮询异常: ${err.message}`
    }
  }, 2000)
}

// ── 加载图谱实体 ──────────────────────────────────────────────────────
async function loadEntities() {
  if (!graphId) return
  entitiesLoading.value = true
  try {
    const res = await axios.get(`${BASE_URL}/api/simulation/entities/${graphId}`)
    const list = res.data?.data?.entities || res.data?.data || []
    const grouped = {}
    for (const e of list) {
      const type = e.entity_type || e.type || '其他'
      if (!grouped[type]) grouped[type] = []
      grouped[type].push({
        name: e.name || e.entity_name || '',
        summary: e.summary || '',
      })
    }
    entitiesByType.value = grouped
  } catch {
    // 静默失败
  } finally {
    entitiesLoading.value = false
  }
}

// ── 加载角色人设 ──────────────────────────────────────────────────────
async function loadProfiles() {
  if (!simulationId) return
  profilesLoading.value = true
  try {
    // 先尝试 twitter JSON（LexSim 新版保存）
    let raw = []
    try {
      const res = await axios.get(
        `${BASE_URL}/api/simulation/${simulationId}/profiles?platform=twitter`
      )
      raw = res.data?.data?.profiles || []
    } catch { /* 文件不存在时降级 */ }

    // 降级：尝试 realtime 接口（读 CSV/DB 实时数据）
    if (!raw.length) {
      try {
        const res2 = await axios.get(
          `${BASE_URL}/api/simulation/${simulationId}/profiles/realtime?platform=twitter`
        )
        raw = res2.data?.data?.profiles || []
      } catch { /* 静默 */ }
    }

    profiles.value = raw.map(p => {
      const interested_topics = p.interested_topics || []
      const court_role = p.court_role || extractCourtRole(interested_topics)
      return {
        name: p.name || p.user_name || p.username || '',
        court_role,
        profession: p.profession || '',
        bio: p.bio || p.description || p.persona || '',
        persona: p.persona || '',
        interested_topics,
      }
    })
  } catch {
    // 静默失败
  } finally {
    profilesLoading.value = false
  }
}

function extractCourtRole(topics) {
  if (!Array.isArray(topics)) return 'other'
  for (const t of topics) {
    const m = String(t).match(/court_role[：:]\s*(\w+)/i)
    if (m) return m[1]
  }
  return 'other'
}

// ── 进入庭审视图（step4 已完成时使用）────────────────────────────────
function goToCourt() {
  router.push({
    path: `/court/${simulationId}`,
    query: { caseName: caseName.value, caseType: caseType.value, graphId },
  })
}

// ── 步骤 4：启动庭审模拟 ─────────────────────────────────────────────
async function startSimulation() {
  if (!graphId) {
    steps.value[3].status = 'error'
    steps.value[3].error = '图谱 ID 缺失，请点击"↺ 重新开始"从步骤2重试'
    return
  }
  if (!simulationId) {
    steps.value[3].status = 'error'
    steps.value[3].error = '模拟 ID 缺失，请点击"↺ 重新开始"从步骤3重试'
    return
  }
  steps.value[3].status = 'running'
  try {
    await axios.post(`${BASE_URL}/api/simulation/start`, {
      simulation_id: simulationId,
      platform: 'twitter',
      max_rounds: 13,
    })
    steps.value[3].status = 'done'
    router.push({
      path: `/court/${simulationId}`,
      query: {
        caseName: caseName.value,
        caseType: caseType.value,
        graphId,
      },
    })
  } catch (err) {
    steps.value[3].status = 'error'
    steps.value[3].error = err.response?.data?.error || err.message
  }
}

// ── 自动检测已有状态（刷新后恢复） ────────────────────────────────────
async function checkExistingState() {
  try {
    // 1. 获取项目信息，判断步骤1/2是否已完成
    const pRes = await axios.get(`${BASE_URL}/api/graph/project/${projectId.value}`)
    const project = pRes.data?.data
    if (!project) { runStep1(); return }

    // ─ Step 1：本体已加载 ─
    const hasOntology = project.ontology && Object.keys(project.ontology).length > 0
    if (!hasOntology) { runStep1(); return }
    ontologyInfo.value = {
      entity_types_count: project.ontology?.entity_types?.length || 0,
      edge_types_count:   project.ontology?.edge_types?.length   || 0,
    }
    steps.value[0].status = 'done'

    // ─ Step 2：图谱已构建 ─
    const gId = project.graph_id || route.query.graphId || ''
    if (!gId || project.status === 'created' || project.status === 'ontology_generated') {
      runStep2(); return
    }
    graphId = gId
    graphInfo.value = { graph_id: gId, node_count: 0, edge_count: 0 }
    steps.value[1].status = 'done'
    router.replace({ query: { ...route.query, graphId: gId } })
    loadEntities()

    // ─ Step 3：庭审配置已生成 ─
    // 优先从 URL 取 simulationId，否则按 project_id 查询模拟列表
    let sId = route.query.simulationId || ''
    if (!sId) {
      try {
        const listRes = await axios.get(`${BASE_URL}/api/simulation/list?project_id=${projectId.value}`)
        const sims = listRes.data?.data || []
        if (sims.length > 0) sId = sims[0].simulation_id
      } catch { /* 忽略 */ }
    }
    if (sId) {
      try {
        const sRes = await axios.get(`${BASE_URL}/api/simulation/${sId}`)
        if (sRes.data?.success) {
          simulationId = sId
          // entity_count / profile_count 通过加载人设数据后自动填充
          prepareInfo.value = { entity_count: 0, profile_count: 0 }
          steps.value[2].status = 'done'
          router.replace({ query: { ...route.query, simulationId: sId } })
          await loadProfiles()
          // 用实际加载到的人设数量填充统计
          if (prepareInfo.value) {
            prepareInfo.value.profile_count = profiles.value.length
            prepareInfo.value.entity_count  = profiles.value.length
          }
        } else {
          runStep3(); return
        }
      } catch { runStep3(); return }
    } else {
      runStep3(); return
    }

    // ─ Step 4：庭审是否已启动 ─
    try {
      const rsRes = await axios.get(`${BASE_URL}/api/simulation/${simulationId}/run-status`)
      const rs = rsRes.data?.data?.runner_status || 'idle'
      if (!['idle', 'starting'].includes(rs)) {
        steps.value[3].status = 'done'
      }
    } catch { /* step4 保持 pending，等用户点击 */ }

  } catch {
    // 获取项目失败，全部从头开始
    runStep1()
  }
}

// ── 重新执行全部步骤 ─────────────────────────────────────────────────
function confirmRerunAll() {
  if (!confirm('确定要重新执行所有准备步骤吗？\n现有图谱与庭审配置将被覆盖重建。')) return
  if (pollTimer) clearInterval(pollTimer)
  ontologyInfo.value = null
  graphInfo.value    = null
  prepareInfo.value  = null
  entitiesByType.value = {}
  profiles.value     = []
  graphId            = ''
  simulationId       = ''
  for (let i = 0; i < steps.value.length; i++) {
    steps.value[i] = { status: 'pending', progress: 0, message: '', error: '' }
  }
  runStep1()
}

// ── 错误重试 ────────────────────────────────────────────────────────
function retryFromError() {
  if (pollTimer) clearInterval(pollTimer)
  const firstErrorIdx = steps.value.findIndex(s => s.status === 'error')
  if (firstErrorIdx === -1) return
  for (let i = firstErrorIdx; i < steps.value.length; i++) {
    steps.value[i] = { status: 'pending', progress: 0, message: '', error: '' }
  }
  if (firstErrorIdx === 0) runStep1()
  else if (firstErrorIdx === 1) runStep2()
  else if (firstErrorIdx === 2) runStep3()
}

onMounted(() => {
  checkExistingState()
})

onUnmounted(() => {
  if (pollTimer) clearInterval(pollTimer)
})
</script>

<style scoped>
.prepare-view {
  min-height: 100vh;
  background: #070d14;
  color: #e2e8f0;
  font-family: 'Inter', 'PingFang SC', sans-serif;
  display: flex;
  flex-direction: column;
}

/* Header */
.prepare-header {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 14px 24px;
  background: #0f1923;
  border-bottom: 1px solid #1e3a5f;
  flex-shrink: 0;
}
.btn-back {
  background: transparent;
  border: 1px solid #1e3a5f;
  color: #64748b;
  border-radius: 6px;
  padding: 6px 12px;
  font-size: 12px;
  cursor: pointer;
  white-space: nowrap;
}
.btn-back:hover { color: #93c5fd; border-color: #2563eb; }
.header-title {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
}
.header-icon { font-size: 24px; }
.header-h1 { margin: 0; font-size: 16px; font-weight: 700; color: #f8fafc; }
.header-sub {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 2px;
}
.case-type-badge {
  font-size: 11px;
  color: #60a5fa;
  background: rgba(37, 99, 235, 0.12);
  border: 1px solid rgba(37, 99, 235, 0.3);
  border-radius: 4px;
  padding: 1px 7px;
}
.project-id {
  font-size: 11px;
  color: #334155;
  font-family: monospace;
}
.header-progress {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
}
.progress-label { font-size: 10px; color: #475569; }
.progress-value { font-size: 14px; font-weight: 600; color: #60a5fa; }

/* Body */
.prepare-body {
  flex: 1;
  max-width: 680px;
  margin: 0 auto;
  padding: 32px 24px;
  width: 100%;
  box-sizing: border-box;
}

/* Pipeline */
.pipeline {
  display: flex;
  flex-direction: column;
}

/* Connector */
.pipeline-connector {
  width: 2px;
  height: 20px;
  background: #1e3a5f;
  margin-left: 19px;
  flex-shrink: 0;
  transition: background 0.4s;
}
.pipeline-connector.active { background: #2563eb; }

/* Step */
.pipeline-step {
  background: #0f1923;
  border: 1px solid #1e3a5f;
  border-radius: 12px;
  padding: 18px 20px;
  transition: border-color 0.3s;
}
.pipeline-step.step-running { border-color: #2563eb; }
.pipeline-step.step-done    { border-color: #1e40af; }
.pipeline-step.step-error   { border-color: #7f1d1d; }

.step-header {
  display: flex;
  align-items: center;
  gap: 14px;
}

/* Step Indicator */
.step-indicator {
  width: 32px;
  height: 32px;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
}
.step-num {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: #1e3a5f;
  color: #475569;
  font-size: 12px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
}
.step-icon {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  font-size: 13px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
}
.step-icon.done  { background: #2563eb; color: #fff; box-shadow: 0 0 8px rgba(37,99,235,0.5); }
.step-icon.running { background: #1e3a5f; }
.step-icon.error { background: #7f1d1d; color: #fca5a5; }

.spinner-sm {
  width: 14px;
  height: 14px;
  border: 2px solid #1e3a5f;
  border-top-color: #3b82f6;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  display: block;
}
@keyframes spin { to { transform: rotate(360deg); } }

/* Step Info */
.step-info { flex: 1 }
.step-title {
  font-size: 14px;
  font-weight: 600;
  color: #e2e8f0;
  margin-bottom: 2px;
}
.step-desc { font-size: 12px; color: #475569; }

/* Step Badge */
.step-badge {
  font-size: 11px;
  padding: 3px 9px;
  border-radius: 12px;
  border: 1px solid;
  flex-shrink: 0;
}
.badge-pending { color: #475569; border-color: #1e3a5f; }
.badge-running { color: #60a5fa; border-color: #2563eb; background: rgba(37,99,235,0.08); }
.badge-done    { color: #34d399; border-color: #065f46; background: rgba(6,95,70,0.1); }
.badge-error   { color: #fca5a5; border-color: #7f1d1d; background: rgba(127,29,29,0.1); }

/* Progress Bar */
.step-progress-wrap {
  margin-top: 12px;
  display: flex;
  align-items: center;
  gap: 8px;
}
.progress-track {
  flex: 1;
  height: 5px;
  background: #1e293b;
  border-radius: 3px;
  overflow: hidden;
}
.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #1d4ed8, #3b82f6);
  border-radius: 3px;
  transition: width 0.5s ease;
}
.progress-pct {
  font-size: 11px;
  color: #60a5fa;
  font-variant-numeric: tabular-nums;
  min-width: 28px;
  text-align: right;
}
.progress-msg {
  font-size: 11px;
  color: #475569;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 220px;
}

/* Step Result */
.step-result {
  margin-top: 10px;
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}
.result-tag {
  font-size: 11px;
  color: #34d399;
  background: rgba(6,95,70,0.12);
  border: 1px solid rgba(52,211,153,0.2);
  border-radius: 4px;
  padding: 2px 8px;
  font-family: monospace;
}
.graph-id-tag {
  color: #60a5fa;
  background: rgba(37,99,235,0.08);
  border-color: rgba(96,165,250,0.2);
}

/* Step Error */
.step-error {
  margin-top: 10px;
  font-size: 12px;
  color: #fca5a5;
  background: rgba(127,29,29,0.1);
  border-radius: 6px;
  padding: 7px 10px;
  font-family: monospace;
}

/* Section Label (替代 Tab，作为小标题) */
.section-label {
  font-size: 11px;
  font-weight: 600;
  color: #475569;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  padding: 12px 0 8px;
  border-top: 1px solid #1e3a5f;
  margin-top: 14px;
}

/* Court Flow Panel */
.flow-panel {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding-top: 0;
}
.flow-phase-block {
  background: #070d14;
  border: 1px solid #1e3a5f;
  border-radius: 8px;
  overflow: hidden;
}
.flow-phase-header {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 12px;
  border-bottom: 1px solid #1e3a5f;
}
.phase-color-0 { background: rgba(148,163,184,0.05); }
.phase-color-1 { background: rgba(37,99,235,0.07); }
.phase-color-2 { background: rgba(180,83,9,0.07); }
.phase-color-3 { background: rgba(124,58,237,0.07); }
.phase-color-4 { background: rgba(6,95,70,0.07); }
.phase-color-5 { background: rgba(217,119,6,0.1); }
.flow-phase-index {
  font-size: 10px;
  color: #334155;
  font-weight: 600;
  flex-shrink: 0;
}
.flow-phase-name {
  font-size: 12px;
  font-weight: 700;
  color: #e2e8f0;
  flex: 1;
}
.flow-phase-rounds {
  font-size: 10px;
  color: #334155;
  flex-shrink: 0;
}
.flow-phase-desc {
  font-size: 11px;
  color: #475569;
  padding: 6px 12px 8px;
  line-height: 1.5;
  border-bottom: 1px solid #1e3a5f;
}
.flow-round-list {
  display: flex;
  flex-direction: column;
  gap: 0;
}
.flow-round-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 5px 12px;
  border-bottom: 1px solid rgba(30,58,95,0.5);
  font-size: 11px;
}
.flow-round-item:last-child { border-bottom: none; }
.flow-round-num {
  width: 28px;
  flex-shrink: 0;
  font-family: monospace;
  font-size: 10px;
  color: #334155;
}
.flow-round-label {
  flex: 1;
  color: #64748b;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flow-round-roles {
  display: flex;
  gap: 3px;
  flex-wrap: wrap;
  justify-content: flex-end;
}
.flow-role-badge {
  font-size: 9px;
  padding: 1px 5px;
  border-radius: 3px;
  border: 1px solid;
}
.flow-role-badge.role-judge            { color: #fbbf24; border-color: rgba(217,119,6,0.4); background: rgba(217,119,6,0.08); }
.flow-role-badge.role-plaintiff_counsel{ color: #60a5fa; border-color: rgba(29,78,216,0.4); background: rgba(29,78,216,0.08); }
.flow-role-badge.role-defense_counsel  { color: #f59e0b; border-color: rgba(180,83,9,0.4); background: rgba(180,83,9,0.08); }
.flow-role-badge.role-prosecutor       { color: #a78bfa; border-color: rgba(124,58,237,0.4); background: rgba(124,58,237,0.08); }
.flow-role-badge.role-plaintiff        { color: #38bdf8; border-color: rgba(3,105,161,0.4); background: rgba(3,105,161,0.08); }
.flow-role-badge.role-defendant        { color: #f87171; border-color: rgba(185,28,28,0.4); background: rgba(185,28,28,0.08); }
.flow-role-badge.role-witness          { color: #34d399; border-color: rgba(6,95,70,0.4); background: rgba(6,95,70,0.08); }
.flow-role-badge.role-expert           { color: #2dd4bf; border-color: rgba(15,118,110,0.4); background: rgba(15,118,110,0.08); }

/* Ontology Detail Panel */
.ontology-detail-panel {
  margin-top: 14px;
  border-top: 1px solid #1e3a5f;
  padding-top: 14px;
}
.ontology-section-title {
  font-size: 11px;
  font-weight: 600;
  color: #475569;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 8px;
}
.ontology-type-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
  gap: 6px;
}
.ontology-type-item {
  background: #070d14;
  border: 1px solid #1e3a5f;
  border-radius: 6px;
  padding: 6px 10px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.ontology-type-item.edge-type { border-left: 2px solid #1d4ed8; }
.otype-name {
  font-size: 11px;
  font-weight: 600;
  color: #94a3b8;
  font-family: monospace;
}
.otype-desc {
  font-size: 10px;
  color: #334155;
}

/* Entities Panel */
.entities-panel {
  margin-top: 14px;
  border-top: 1px solid #1e3a5f;
  padding-top: 14px;
}
.entities-content {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.entity-group {
  background: #070d14;
  border: 1px solid #1e3a5f;
  border-radius: 8px;
  overflow: hidden;
}
.entity-type-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 6px 12px;
  background: rgba(37,99,235,0.06);
  border-bottom: 1px solid #1e3a5f;
}
.entity-type-name {
  font-size: 12px;
  font-weight: 600;
  color: #60a5fa;
}
.entity-type-count {
  font-size: 11px;
  color: #334155;
}
.entity-list {
  padding: 8px 12px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.entity-item {
  display: flex;
  align-items: baseline;
  gap: 6px;
  font-size: 12px;
}
.entity-dot { color: #334155; flex-shrink: 0; }
.entity-name {
  color: #cbd5e1;
  font-weight: 500;
  flex-shrink: 0;
  max-width: 120px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.entity-summary {
  color: #475569;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  flex: 1;
  min-width: 0;
}
/* Profiles Panel */
.profiles-panel {
  margin-top: 14px;
  border-top: 1px solid #1e3a5f;
  padding-top: 14px;
}
.profiles-loading {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  color: #475569;
  padding: 8px 0;
}
.profiles-empty { font-size: 12px; color: #475569; padding: 8px 0; }

.profiles-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: 10px;
}

.profile-card {
  background: #070d14;
  border: 1px solid #1e3a5f;
  border-radius: 10px;
  padding: 12px 14px;
  transition: border-color 0.2s;
}
.profile-card:hover { border-color: #2563eb; }
.profile-card.role-judge         { border-left: 3px solid #d97706; }
.profile-card.role-plaintiff_counsel { border-left: 3px solid #1d4ed8; }
.profile-card.role-defense_counsel   { border-left: 3px solid #b45309; }
.profile-card.role-prosecutor    { border-left: 3px solid #7c3aed; }
.profile-card.role-plaintiff     { border-left: 3px solid #0369a1; }
.profile-card.role-defendant     { border-left: 3px solid #b91c1c; }
.profile-card.role-witness       { border-left: 3px solid #065f46; }
.profile-card.role-expert        { border-left: 3px solid #0f766e; }

.profile-card-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 8px;
  flex-wrap: wrap;
}
.profile-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  font-weight: 700;
  flex-shrink: 0;
  background: #1e3a5f;
  color: #64748b;
}
.avatar-judge         { background: rgba(217,119,6,0.2); color: #fbbf24; }
.avatar-plaintiff_counsel { background: rgba(29,78,216,0.2); color: #60a5fa; }
.avatar-defense_counsel   { background: rgba(180,83,9,0.2); color: #f59e0b; }
.avatar-prosecutor    { background: rgba(124,58,237,0.2); color: #a78bfa; }
.avatar-plaintiff     { background: rgba(3,105,161,0.2); color: #38bdf8; }
.avatar-defendant     { background: rgba(185,28,28,0.2); color: #f87171; }
.avatar-witness       { background: rgba(6,95,70,0.2); color: #34d399; }
.avatar-expert        { background: rgba(15,118,110,0.2); color: #2dd4bf; }

.profile-name-block { flex: 1; min-width: 0; }
.profile-name {
  font-size: 13px;
  font-weight: 600;
  color: #e2e8f0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.profile-role-badge {
  font-size: 10px;
  color: #64748b;
  margin-top: 1px;
}
.profile-profession {
  font-size: 10px;
  color: #475569;
  background: #0f1923;
  border: 1px solid #1e3a5f;
  border-radius: 4px;
  padding: 1px 6px;
  flex-shrink: 0;
}
.profile-bio {
  font-size: 12px;
  color: #64748b;
  line-height: 1.5;
  margin-bottom: 8px;
}
.profile-topics {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}
.topic-tag {
  font-size: 10px;
  color: #334155;
  background: rgba(30,58,95,0.5);
  border-radius: 3px;
  padding: 1px 6px;
}

/* Start Area */
.start-area {
  margin-top: 14px;
  display: flex;
  align-items: center;
  gap: 14px;
}
.btn-start {
  background: #2563eb;
  border: none;
  color: #fff;
  border-radius: 8px;
  padding: 10px 24px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
  white-space: nowrap;
}
.btn-start:hover { background: #1d4ed8; }
.start-hint {
  font-size: 12px;
  color: #475569;
}

/* 进入庭审（已启动时） */
.btn-enter {
  background: #065f46 !important;
  border: 1px solid #059669 !important;
}
.btn-enter:hover { background: #047857 !important; }

/* 操作栏（错误重试 + 重新执行） */
.action-bar {
  margin-top: 20px;
  display: flex;
  justify-content: center;
  gap: 12px;
  flex-wrap: wrap;
}
.btn-retry {
  background: transparent;
  border: 1px solid #7f1d1d;
  color: #fca5a5;
  border-radius: 8px;
  padding: 9px 20px;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-retry:hover { background: rgba(127,29,29,0.15); }
.btn-rerun {
  background: transparent;
  border: 1px solid #92400e;
  color: #fbbf24;
  border-radius: 8px;
  padding: 9px 20px;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.2s;
}
.btn-rerun:hover { background: rgba(146,64,14,0.15); }
</style>
