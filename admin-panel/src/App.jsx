import { Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider } from './context/AuthContext'
import ProtectedRoute from './components/ProtectedRoute'
import Layout from './components/Layout'
import LoginPage from './pages/LoginPage'
import DashboardPage from './pages/DashboardPage'
import UsersListPage from './pages/UsersListPage'
import UserDetailPage from './pages/UserDetailPage'
import SearchPage from './pages/SearchPage'
import AnnouncementPage from './pages/AnnouncementPage'
import AdminsPage from './pages/AdminsPage'
import AuditLogPage from './pages/AuditLogPage'
import ProblemReportsPage from './pages/ProblemReportsPage'
import AppConfigPage from './pages/AppConfigPage'
import FaqManagementPage from './pages/FaqManagementPage'
import PolicyAcceptancePage from './pages/PolicyAcceptancePage'

export default function App() {
  return (
    <AuthProvider>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route
          element={
            <ProtectedRoute>
              <Layout />
            </ProtectedRoute>
          }
        >
          <Route path="/dashboard" element={<DashboardPage />} />
          <Route path="/users" element={<UsersListPage />} />
          <Route path="/users/:uid" element={<UserDetailPage />} />
          <Route path="/search" element={<SearchPage />} />
          <Route path="/announcement" element={<AnnouncementPage />} />
          <Route path="/app-config" element={<AppConfigPage />} />
          <Route path="/app-config/faq" element={<FaqManagementPage />} />
          <Route path="/app-config/policy-acceptance" element={<PolicyAcceptancePage />} />
          <Route path="/admins" element={<AdminsPage />} />
          <Route path="/audit-log" element={<AuditLogPage />} />
          <Route path="/problem-reports" element={<ProblemReportsPage />} />
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Route>
      </Routes>
    </AuthProvider>
  )
}
