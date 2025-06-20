import { BrowserRouter, Routes, Route } from "react-router-dom";
import HeaderComponent from "./components/common/HeaderComponent";
import FooterComponent from "./components/common/FooterComponent";
import ListEmployeeComponent from "./components/ListEmployeeComponent";
import EmployeeComponent from "./components/EmployeeComponent";
import ListDepartmentComponent from "./components/ListDepartmentComponent";
import DepartmentComponent from "./components/DepartmentComponent";

function App() {
  return (
    <BrowserRouter>
      <div className="employee-management-app">
        <HeaderComponent />
        <main className="main-content">
          <Routes>
            {/* // http://localhost:3000 */}
            <Route path="/" element={<ListEmployeeComponent />}></Route>
            {/* // http://localhost:3000/employees */}
            <Route path="/employees" element={<ListEmployeeComponent />}></Route>
            <Route path="/add-employee" element={<EmployeeComponent />} />
            <Route path="/edit-employee/:id" element={<EmployeeComponent />} />
            <Route path="/departments" element={<ListDepartmentComponent />} />
            <Route path="/add-department" element={<DepartmentComponent />} />
            <Route path="/edit-department/:id" element={<DepartmentComponent />} />
          </Routes>
        </main>
        <FooterComponent />
      </div>
    </BrowserRouter>
  );
}

export default App;