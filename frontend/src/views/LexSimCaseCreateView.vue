<template>
  <div class="case-create-view">
    <!-- 顶部导航 -->
    <header class="create-header">
      <button class="btn-back" @click="router.push('/')">← 返回首页</button>
      <div class="header-title">
        <span class="header-icon">⚖</span>
        <div>
          <h1 class="header-h1">LexSim 法律庭审模拟</h1>
          <span class="header-sub">创建新案件</span>
        </div>
      </div>
    </header>

    <div class="create-body">
      <div class="create-card">
        <!-- 案件基本信息 -->
        <section class="form-section">
          <div class="section-title">案件信息</div>

          <div class="form-row">
            <label class="form-label">案件名称 <span class="required">*</span></label>
            <input
              v-model="caseName"
              class="form-input"
              placeholder="例：某公司劳动合同纠纷案"
              maxlength="80"
            />
          </div>

          <div class="form-row">
            <label class="form-label">案件类型 <span class="required">*</span></label>
            <div class="type-selector">
              <button
                class="type-btn"
                :class="{ active: caseType === 'civil' }"
                @click="caseType = 'civil'"
              >
                <span class="type-icon">📜</span>
                <span class="type-name">民事案件</span>
                <span class="type-desc">合同纠纷、侵权、婚姻财产等</span>
              </button>
              <button
                class="type-btn"
                :class="{ active: caseType === 'criminal' }"
                @click="caseType = 'criminal'"
              >
                <span class="type-icon">🔏</span>
                <span class="type-name">刑事案件</span>
                <span class="type-desc">公诉案件、刑事附带民事等</span>
              </button>
            </div>

            <!-- 本体模板预览 -->
            <div class="ontology-preview">
              <div class="ontology-preview-title">
                {{ caseType === 'civil' ? '民事' : '刑事' }}案件本体模板
                <span class="ontology-count">{{ ONTOLOGY_TEMPLATES[caseType].entity_types.length }} 个实体类型 · {{ ONTOLOGY_TEMPLATES[caseType].edge_types.length }} 个关系类型</span>
              </div>
              <div class="ontology-entity-list">
                <div
                  v-for="et in ONTOLOGY_TEMPLATES[caseType].entity_types"
                  :key="et.name"
                  class="ontology-entity-item"
                >
                  <span class="ontology-entity-name">{{ et.name }}</span>
                  <span class="ontology-entity-desc">{{ et.desc }}</span>
                </div>
              </div>
            </div>
          </div>

          <div class="form-row">
            <label class="form-label">模拟需求描述</label>
            <textarea
              v-model="requirement"
              class="form-textarea"
              rows="3"
              :placeholder="`例：模拟${caseName || '本案'}的完整庭审过程，重点分析证据采信和法律适用，预测判决结果`"
            />
            <span class="form-hint">描述您希望模拟庭审的侧重点，不填则使用默认描述</span>
          </div>
        </section>

        <!-- 案件材料上传 -->
        <section class="form-section">
          <div class="section-title">案件材料 <span class="section-note">（可选，支持 PDF / TXT / MD）</span></div>

          <div
            class="upload-zone"
            :class="{ 'is-dragging': isDragging }"
            @dragover.prevent="isDragging = true"
            @dragleave="isDragging = false"
            @drop.prevent="handleDrop"
            @click="fileInputRef.click()"
          >
            <input
              ref="fileInputRef"
              type="file"
              multiple
              accept=".pdf,.txt,.md"
              style="display: none"
              @change="handleFileChange"
            />
            <div v-if="files.length === 0" class="upload-placeholder">
              <div class="upload-icon">📁</div>
              <p class="upload-text">拖拽文件到此处，或点击选择文件</p>
              <p class="upload-hint">支持案件材料、起诉状、判决书、证据清单等文档</p>
            </div>
            <div v-else class="file-list">
              <div v-for="(f, i) in files" :key="i" class="file-item">
                <span class="file-icon">{{ getFileIcon(f.name) }}</span>
                <span class="file-name">{{ f.name }}</span>
                <span class="file-size">{{ formatSize(f.size) }}</span>
                <button class="file-remove" @click.stop="removeFile(i)">✕</button>
              </div>
              <div class="file-add" @click.stop="fileInputRef.click()">+ 继续添加文件</div>
            </div>
          </div>
        </section>

        <!-- 提交按钮 -->
        <div class="form-footer">
          <div v-if="errorMsg" class="error-msg">{{ errorMsg }}</div>
          <button
            class="btn-submit"
            :disabled="!canSubmit || submitting"
            @click="submit"
          >
            <span v-if="submitting" class="btn-spinner" />
            {{ submitting ? '创建中...' : '创建案件并开始准备' }}
          </button>
        </div>
      </div>

      <!-- 流程说明 -->
      <div class="flow-hint">
        <div class="flow-title">庭审模拟流程</div>
        <div class="flow-steps">
          <div class="flow-step active">
            <div class="flow-dot active">1</div>
            <span>创建案件</span>
          </div>
          <div class="flow-arrow">→</div>
          <div class="flow-step">
            <div class="flow-dot">2</div>
            <span>构建图谱</span>
          </div>
          <div class="flow-arrow">→</div>
          <div class="flow-step">
            <div class="flow-dot">3</div>
            <span>庭审准备</span>
          </div>
          <div class="flow-arrow">→</div>
          <div class="flow-step">
            <div class="flow-dot">4</div>
            <span>庭审模拟</span>
          </div>
          <div class="flow-arrow">→</div>
          <div class="flow-step">
            <div class="flow-dot">5</div>
            <span>判决预测</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios'

const BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5001'

const router = useRouter()

const caseName = ref('')
const caseType = ref('civil')
const requirement = ref('')
const files = ref([])
const isDragging = ref(false)
const submitting = ref(false)
const errorMsg = ref('')
const fileInputRef = ref(null)

// 本体模板静态数据（来自后端 lexsim_ontology_templates）
const ONTOLOGY_TEMPLATES = {
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
      { name: 'REPRESENTS',   desc: '律师代理当事人' },
      { name: 'SUBMITS',      desc: '提交证据' },
      { name: 'TESTIFIES_FOR',desc: '出庭为一方作证' },
      { name: 'CONTRADICTS',  desc: '证据/陈述相互矛盾' },
      { name: 'SUPPORTS',     desc: '证据支持某方主张' },
      { name: 'FILES_AGAINST',desc: '原告起诉被告' },
      { name: 'EMPLOYED_BY',  desc: '雇佣/劳动关系' },
      { name: 'OWNS',         desc: '所有权关系' },
      { name: 'CONTRACTS_WITH',desc: '合同关系' },
      { name: 'WITNESSED',    desc: '目击/知晓某事件' },
    ],
  },
  criminal: {
    entity_types: [
      { name: 'Judge',        desc: '刑事案件主审法官' },
      { name: 'Prosecutor',   desc: '公诉检察官' },
      { name: 'DefenseLawyer',desc: '辩护律师' },
      { name: 'Defendant',    desc: '被告人/被追诉人' },
      { name: 'Victim',       desc: '被害人/受害方' },
      { name: 'Witness',      desc: '证人/出庭陈述' },
      { name: 'Expert',       desc: '法医/技术鉴定专家' },
      { name: 'Court',        desc: '审理本案的法院' },
      { name: 'Person',       desc: '其他涉案自然人' },
      { name: 'Organization', desc: '其他涉案机构/单位' },
    ],
    edge_types: [
      { name: 'DEFENDS',          desc: '辩护律师为被告辩护' },
      { name: 'PROSECUTES',       desc: '检察官提起公诉' },
      { name: 'TESTIFIES_AGAINST',desc: '证人/被害人指证' },
      { name: 'TESTIFIES_FOR',    desc: '证人为被告作证' },
      { name: 'HARMED_BY',        desc: '被害人被告伤害' },
      { name: 'COMMITTED',        desc: '被告实施犯罪行为' },
      { name: 'WITNESSED',        desc: '目击/知晓犯罪过程' },
      { name: 'PROVIDES_EVIDENCE',desc: '提供技术鉴定意见' },
      { name: 'ACCOMPLICE_OF',    desc: '共同犯罪关系' },
      { name: 'VICTIM_OF',        desc: '受害关系' },
    ],
  },
}

const canSubmit = computed(() => caseName.value.trim().length > 0)

function handleDrop(e) {
  isDragging.value = false
  const dropped = Array.from(e.dataTransfer.files).filter(f =>
    /\.(pdf|txt|md)$/i.test(f.name)
  )
  files.value = [...files.value, ...dropped]
}

function handleFileChange(e) {
  const selected = Array.from(e.target.files)
  files.value = [...files.value, ...selected]
  e.target.value = ''
}

function removeFile(idx) {
  files.value.splice(idx, 1)
}

function getFileIcon(name) {
  if (/\.pdf$/i.test(name)) return '📄'
  if (/\.md$/i.test(name)) return '📝'
  return '📃'
}

function formatSize(bytes) {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`
}

async function submit() {
  if (!canSubmit.value || submitting.value) return
  submitting.value = true
  errorMsg.value = ''

  try {
    const formData = new FormData()
    formData.append('case_name', caseName.value.trim())
    formData.append('case_type', caseType.value)

    const req = requirement.value.trim() ||
      `模拟${caseName.value.trim()}的完整庭审过程，预测判决结果`
    formData.append('simulation_requirement', req)

    files.value.forEach(f => formData.append('files', f))

    const res = await axios.post(`${BASE_URL}/api/lexsim/case/create`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    })

    const projectId = res.data?.data?.project_id
    if (!projectId) throw new Error('未获取到项目 ID')

    router.push({
      path: `/lexsim/prepare/${projectId}`,
      query: {
        caseName: caseName.value.trim(),
        caseType: caseType.value,
      },
    })
  } catch (err) {
    errorMsg.value = err.response?.data?.error || err.message
    submitting.value = false
  }
}
</script>

<style scoped>
.case-create-view {
  min-height: 100vh;
  background: #070d14;
  color: #e2e8f0;
  font-family: 'Inter', 'PingFang SC', sans-serif;
  display: flex;
  flex-direction: column;
}

/* Header */
.create-header {
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
}
.header-icon { font-size: 24px; }
.header-h1 { margin: 0; font-size: 16px; font-weight: 700; color: #f8fafc; }
.header-sub { font-size: 12px; color: #64748b; }

/* Body */
.create-body {
  flex: 1;
  max-width: 720px;
  margin: 0 auto;
  padding: 32px 24px;
  width: 100%;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* Card */
.create-card {
  background: #0f1923;
  border: 1px solid #1e3a5f;
  border-radius: 16px;
  overflow: hidden;
}

/* Form Section */
.form-section {
  padding: 24px 28px;
  border-bottom: 1px solid #1e3a5f;
}
.form-section:last-child { border-bottom: none; }
.section-title {
  font-size: 13px;
  font-weight: 600;
  color: #60a5fa;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  margin-bottom: 18px;
}
.section-note {
  font-size: 11px;
  color: #475569;
  font-weight: 400;
  text-transform: none;
  letter-spacing: 0;
}

.form-row { margin-bottom: 18px; }
.form-row:last-child { margin-bottom: 0; }
.form-label {
  display: block;
  font-size: 13px;
  color: #94a3b8;
  margin-bottom: 7px;
}
.required { color: #ef4444; margin-left: 2px; }

.form-input {
  width: 100%;
  background: #070d14;
  border: 1px solid #1e3a5f;
  border-radius: 8px;
  padding: 9px 14px;
  font-size: 14px;
  color: #e2e8f0;
  outline: none;
  box-sizing: border-box;
  transition: border-color 0.2s;
}
.form-input:focus { border-color: #2563eb; }
.form-input::placeholder { color: #334155; }

.form-textarea {
  width: 100%;
  background: #070d14;
  border: 1px solid #1e3a5f;
  border-radius: 8px;
  padding: 9px 14px;
  font-size: 14px;
  color: #e2e8f0;
  outline: none;
  resize: vertical;
  box-sizing: border-box;
  font-family: inherit;
  transition: border-color 0.2s;
}
.form-textarea:focus { border-color: #2563eb; }
.form-textarea::placeholder { color: #334155; }
.form-hint { display: block; font-size: 11px; color: #334155; margin-top: 5px; }

/* Type Selector */
.type-selector {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}
.type-btn {
  background: #070d14;
  border: 2px solid #1e3a5f;
  border-radius: 10px;
  padding: 16px;
  cursor: pointer;
  text-align: left;
  transition: all 0.2s;
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.type-btn:hover { border-color: #2563eb; }
.type-btn.active { border-color: #2563eb; background: rgba(37, 99, 235, 0.08); }
.type-icon { font-size: 20px; }
.type-name { font-size: 14px; font-weight: 600; color: #e2e8f0; }
.type-desc { font-size: 11px; color: #475569; }
.type-btn.active .type-name { color: #93c5fd; }

/* Ontology Preview */
.ontology-preview {
  margin-top: 12px;
  background: #070d14;
  border: 1px solid #1e3a5f;
  border-radius: 8px;
  overflow: hidden;
}
.ontology-preview-title {
  font-size: 11px;
  font-weight: 600;
  color: #60a5fa;
  padding: 8px 12px;
  background: rgba(37,99,235,0.06);
  border-bottom: 1px solid #1e3a5f;
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.ontology-count {
  font-weight: 400;
  color: #334155;
}
.ontology-entity-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 1px;
  background: #1e3a5f;
}
.ontology-entity-item {
  background: #070d14;
  padding: 6px 12px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.ontology-entity-name {
  font-size: 11px;
  font-weight: 600;
  color: #94a3b8;
  font-family: monospace;
}
.ontology-entity-desc {
  font-size: 10px;
  color: #334155;
}

/* Upload Zone */
.upload-zone {
  border: 2px dashed #1e3a5f;
  border-radius: 10px;
  min-height: 120px;
  cursor: pointer;
  transition: all 0.2s;
  overflow: hidden;
}
.upload-zone:hover, .upload-zone.is-dragging {
  border-color: #2563eb;
  background: rgba(37, 99, 235, 0.04);
}
.upload-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 28px;
  gap: 8px;
}
.upload-icon { font-size: 32px; opacity: 0.5; }
.upload-text { font-size: 14px; color: #64748b; margin: 0; }
.upload-hint { font-size: 11px; color: #334155; margin: 0; }

.file-list { padding: 12px; }
.file-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 10px;
  background: #070d14;
  border-radius: 6px;
  margin-bottom: 6px;
  font-size: 13px;
}
.file-icon { flex-shrink: 0; }
.file-name { flex: 1; color: #cbd5e1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.file-size { color: #475569; font-size: 11px; flex-shrink: 0; }
.file-remove {
  background: none;
  border: none;
  color: #475569;
  cursor: pointer;
  padding: 2px 6px;
  border-radius: 4px;
  flex-shrink: 0;
}
.file-remove:hover { color: #ef4444; background: rgba(239,68,68,0.1); }
.file-add {
  font-size: 12px;
  color: #2563eb;
  padding: 6px 10px;
  cursor: pointer;
  border-radius: 4px;
}
.file-add:hover { background: rgba(37,99,235,0.08); }

/* Footer */
.form-footer {
  padding: 20px 28px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.error-msg {
  font-size: 13px;
  color: #ef4444;
  background: rgba(239,68,68,0.08);
  border: 1px solid rgba(239,68,68,0.2);
  border-radius: 6px;
  padding: 8px 12px;
}
.btn-submit {
  background: #2563eb;
  border: none;
  color: #fff;
  border-radius: 8px;
  padding: 12px 28px;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}
.btn-submit:hover:not(:disabled) { background: #1d4ed8; }
.btn-submit:disabled { opacity: 0.45; cursor: not-allowed; }
.btn-spinner {
  width: 16px;
  height: 16px;
  border: 2px solid rgba(255,255,255,0.3);
  border-top-color: #fff;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  flex-shrink: 0;
}
@keyframes spin { to { transform: rotate(360deg); } }

/* Flow Hint */
.flow-hint {
  background: #0f1923;
  border: 1px solid #1e3a5f;
  border-radius: 12px;
  padding: 16px 20px;
}
.flow-title {
  font-size: 11px;
  color: #475569;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 14px;
}
.flow-steps {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}
.flow-step {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #475569;
}
.flow-step.active { color: #93c5fd; }
.flow-dot {
  width: 22px;
  height: 22px;
  border-radius: 50%;
  background: #1e3a5f;
  color: #64748b;
  font-size: 11px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
}
.flow-dot.active {
  background: #2563eb;
  color: #fff;
  box-shadow: 0 0 8px rgba(37,99,235,0.5);
}
.flow-arrow { color: #1e3a5f; font-size: 14px; }
</style>
